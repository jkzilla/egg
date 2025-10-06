#!/bin/bash
set -e

echo "🌼 Launching Hailey's Garden — Full Auto Deploy with HTTPS (K3s + ACM)"

# ───────────────────────────────
# CONFIGURATION
INSTANCE_NAME="haileys-garden-k3s"
INSTANCE_TYPE="t3.micro"
AMI_ID="ami-0e86e20dae9224db8"  # Ubuntu 22.04 LTS
KEY_NAME="haileys-garden-key"
SG_NAME="haileys-garden-sg"
ALB_SG_NAME="haileys-garden-alb-sg"
REGION="us-east-1"
VPC_ID="vpc-d470ccb0"  # Your VPC ID
ACM_CERT_ARN="arn:aws:acm:us-east-1:011229313364:certificate/1788d41a-e53e-473e-8579-4c3eed565dea"
DOCKER_IMAGE="zealousidealowl/haileys-garden:latest"
APP_PORT=8080
DOMAIN="haileysgarden.com"
# ───────────────────────────────

echo "🐳 Building and pushing Docker image..."
docker build -t $DOCKER_IMAGE .
docker push $DOCKER_IMAGE
echo "✅ Docker image pushed to Docker Hub"

mkdir -p ~/.ssh

# ─── Create SSH Key Pair (if missing) ───────────────────────────────
if ! aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION &>/dev/null; then
  echo "📝 Creating SSH key pair..."
  aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --region $REGION \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/${KEY_NAME}.pem
  chmod 400 ~/.ssh/${KEY_NAME}.pem
  echo "✅ Key saved to ~/.ssh/${KEY_NAME}.pem"
else
  echo "✅ Key pair already exists"
fi

# ─── Create or Reuse Security Group ───────────────────────────────
if aws ec2 describe-security-groups --group-names $SG_NAME --region $REGION &>/dev/null; then
  SG_ID=$(aws ec2 describe-security-groups \
    --group-names $SG_NAME \
    --region $REGION \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
  echo "✅ Security group already exists: $SG_ID"
else
  echo "🔒 Creating security group..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SG_NAME \
    --description "Security group for Hailey's Garden K3s cluster" \
    --region $REGION \
    --query 'GroupId' \
    --output text)
  echo "✅ Created security group: $SG_ID"

  MY_IP=$(curl -s https://checkip.amazonaws.com)
  echo "📍 Your IP: $MY_IP"

  aws ec2 authorize-security-group-ingress --group-id $SG_ID --region $REGION --ip-permissions '[
    {"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"'${MY_IP}'/32"}]},
    {"IpProtocol":"tcp","FromPort":8080,"ToPort":8080,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}
  ]' 2>/dev/null || echo "Security group rules already exist"
fi

# ─── Create ALB Security Group
echo "🔒 Creating ALB security group..."
if aws ec2 describe-security-groups --group-names $ALB_SG_NAME --region $REGION &>/dev/null; then
  ALB_SG_ID=$(aws ec2 describe-security-groups \
    --group-names $ALB_SG_NAME \
    --region $REGION \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
  echo "✅ ALB security group exists: $ALB_SG_ID"
else
  ALB_SG_ID=$(aws ec2 create-security-group \
    --group-name $ALB_SG_NAME \
    --description "Security group for Haileys Garden ALB" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text)
  echo "✅ Created ALB security group: $ALB_SG_ID"

  # Allow HTTP and HTTPS from anywhere
  aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --region $REGION --ip-permissions '[
    {"IpProtocol":"tcp","FromPort":80,"ToPort":80,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]},
    {"IpProtocol":"tcp","FromPort":443,"ToPort":443,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}
  ]'
fi

# Update instance security group to allow traffic from ALB
echo "🔐 Updating instance security group to allow ALB traffic..."
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --source-group $ALB_SG_ID \
  --region $REGION 2>/dev/null || echo "ALB ingress rule already exists"

# ─── Define EC2 User Data (Auto-provision script) ───────────────────────────────
USER_DATA=$(cat <<'EOF'
#!/bin/bash
set -xe

# Update system
apt-get update -y && apt-get install -y curl

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Wait for K3s to initialize
sleep 30

# Set up kubectl access
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config

# Clone the repository to get the latest K8s manifests
cd /tmp
git clone https://github.com/jkzilla/egg.git
cd egg/k8s

# Apply all K8s manifests in order
/usr/local/bin/kubectl apply -f 00-namespace.yaml
/usr/local/bin/kubectl apply -f 01-configmap.yaml
/usr/local/bin/kubectl apply -f 02-secret.yaml
/usr/local/bin/kubectl apply -f 03-deployment.yaml
/usr/local/bin/kubectl apply -f 04-service.yaml
/usr/local/bin/kubectl apply -f 05-signal-api-deployment.yaml
/usr/local/bin/kubectl apply -f 06-nginx-ingress-controller.yaml
/usr/local/bin/kubectl apply -f 07-ingress.yaml

# Wait for deployments to be ready
/usr/local/bin/kubectl wait --for=condition=available --timeout=300s deployment/egg-shop -n haileys-garden
/usr/local/bin/kubectl wait --for=condition=available --timeout=300s deployment/signal-api -n haileys-garden

# Get the NGINX Ingress NodePort for HTTP
NGINX_HTTP_PORT=\$(/usr/local/bin/kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# Create systemd service for port forwarding to NGINX Ingress
cat > /etc/systemd/system/port-forward-8080.service <<SYSTEMD
[Unit]
Description=Forward port 8080 to NGINX Ingress
After=network.target k3s.service

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:8080,fork,reuseaddr TCP:localhost:\${NGINX_HTTP_PORT}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Install socat and enable port forwarding
apt-get install -y socat
systemctl daemon-reload
systemctl enable port-forward-8080
systemctl start port-forward-8080

echo "🌼 Hailey's Garden deployed with NGINX Ingress and Signal API"
EOF
)

# Replace placeholder with actual Docker image
USER_DATA="${USER_DATA//DOCKER_IMAGE_PLACEHOLDER/$DOCKER_IMAGE}"

# ─── Launch EC2 Instance ───────────────────────────────
echo "🚀 Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --user-data "$USER_DATA" \
  --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=30,VolumeType=gp3}' \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --region $REGION \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "✅ Instance launched: $INSTANCE_ID"

# ─── Wait for Instance to Start ───────────────────────────────
for i in {1..30}; do
  STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query "Reservations[0].Instances[0].State.Name" --output text)
  if [[ "$STATE" == "running" ]]; then
    echo "✅ Instance is running!"
    break
  fi
  echo "⏱️  Still pending... ($i/30)"
  sleep 5
done

# ─── Get Public IP ───────────────────────────────
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# ─── Get Subnets for ALB ───────────────────────────────
echo "🌐 Getting VPC subnets..."
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region $REGION \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

# ─── Create Target Group ───────────────────────────────
echo "🎯 Creating target group..."
TG_ARN=$(aws elbv2 create-target-group \
  --name haileys-garden-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --health-check-path / \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || \
  aws elbv2 describe-target-groups \
    --names haileys-garden-tg \
    --region $REGION \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo "✅ Target group: $TG_ARN"

# ─── Register Instance with Target Group ───────────────────────────────
echo "📝 Registering instance with target group..."
aws elbv2 register-targets \
  --target-group-arn $TG_ARN \
  --targets Id=$INSTANCE_ID \
  --region $REGION

# ─── Create Application Load Balancer ───────────────────────────────
echo "⚖️  Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name haileys-garden-alb \
  --subnets $(echo $SUBNETS | tr ',' ' ') \
  --security-groups $ALB_SG_ID \
  --region $REGION \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || \
  aws elbv2 describe-load-balancers \
    --names haileys-garden-alb \
    --region $REGION \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo "✅ ALB created: $ALB_ARN"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region $REGION \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# ─── Create HTTPS Listener ───────────────────────────────
echo "🔐 Creating HTTPS listener..."
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$ACM_CERT_ARN \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN \
  --region $REGION 2>/dev/null || echo "HTTPS listener already exists"

# ─── Create HTTP Listener (redirect to HTTPS) ───────────────────────────────
echo "🔀 Creating HTTP to HTTPS redirect..."
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}" \
  --region $REGION 2>/dev/null || echo "HTTP listener already exists"

echo ""
echo "✅ K3s + Docker + HTTPS Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Instance ID:  $INSTANCE_ID"
echo "Public IP:    $PUBLIC_IP"
echo "ALB DNS:      $ALB_DNS"
echo "App URL:      https://${DOMAIN}"
echo "Docker Image: $DOCKER_IMAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Instance info saved to ec2-instance-info.txt"
cat > ec2-instance-info.txt <<EOF
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
ALB DNS: $ALB_DNS
App URL: https://${DOMAIN}
SSH Command: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP}
Region: $REGION
Docker Image: $DOCKER_IMAGE
Target Group: $TG_ARN
Load Balancer: $ALB_ARN
EOF

echo ""
echo "⏳ Deployment will take ~2-3 minutes"
echo "📊 Monitor: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP} 'sudo tail -f /var/log/cloud-init-output.log'"
echo ""
echo "🌐 Update DNS to point to ALB:"
echo "   CNAME: $DOMAIN -> $ALB_DNS"
echo "   CNAME: www.$DOMAIN -> $ALB_DNS"
