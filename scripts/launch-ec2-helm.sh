#!/bin/bash
set -e

# Configuration
REGION="us-east-1"
AMI_ID="ami-0e2c8caa4b6378d8c"
INSTANCE_TYPE="t3.small"
KEY_NAME="haileys-garden-key"
SECURITY_GROUP="haileys-garden-sg"
SUBNET_ID="subnet-0b22bf6e"
TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:us-east-1:011229313364:targetgroup/haileys-garden-tg/db59fff41eeb9268"

# User data script
USER_DATA=$(cat <<'USERDATA'
#!/bin/bash
set -e

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
sleep 30

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Clone repo
cd /tmp
git clone https://github.com/jkzilla/egg.git
cd egg

# Install NGINX Ingress with hostPort on 8080
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.hostPort.enabled=true \
  --set controller.hostPort.ports.http=8080 \
  --set controller.hostPort.ports.https=8443 \
  --set controller.service.type=ClusterIP \
  --wait --timeout 5m

# Install Hailey's Garden app
helm install haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --create-namespace \
  --wait --timeout 5m

echo "Deployment complete! App should be accessible on port 8080"
USERDATA
)

# Launch instance
echo "🚀 Launching EC2 instance with Helm deployment..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids sg-07044fcbb0e37f92e \
  --subnet-id $SUBNET_ID \
  --user-data "$USER_DATA" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=haileys-garden-k3s-helm}]" \
  --region $REGION \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Public IP: $PUBLIC_IP"

# Register with target group
aws elbv2 register-targets --target-group-arn $TARGET_GROUP_ARN --targets Id=$INSTANCE_ID --region $REGION

# Save info
cat > ec2-instance-info.txt <<INFO
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Deployment: Helm
SSH: ssh -i ~/.ssh/garden2.pem ubuntu@$PUBLIC_IP
INFO

echo "✅ Deployment complete!"
