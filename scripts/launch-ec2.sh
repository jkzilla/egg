#!/bin/bash
set -e

echo "🌱 Launching Hailey's Garden — Full Auto K3s + Go App Deployment"

# ───────────────────────────────
# Configuration
INSTANCE_NAME="haileys-garden-k3s"
INSTANCE_TYPE="t3.micro"
AMI_ID="ami-0e86e20dae9224db8"  # Ubuntu 22.04 LTS in us-east-1
KEY_NAME="haileys-garden-key"
SG_NAME="haileys-garden-sg"
REGION="us-east-1"
APP_REPO="https://github.com/jkzilla/egg.git"   # 🔹 Replace with your Go app repo
APP_PORT=8080
# ───────────────────────────────

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
    {"IpProtocol":"tcp","FromPort":80,"ToPort":80,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]},
    {"IpProtocol":"tcp","FromPort":443,"ToPort":443,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]},
    {"IpProtocol":"tcp","FromPort":8080,"ToPort":8080,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}
  ]'
fi

# ─── Define EC2 User Data (Auto-provision script) ───────────────────────────────
USER_DATA=$(cat <<EOF
#!/bin/bash
set -xe
# Update system
apt-get update -y && apt-get install -y curl git

# Install K3s
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Wait for K3s to initialize
sleep 20

# Set up kubectl access
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chmod 600 /root/.kube/config

# Clone your Go app repo
cd /home/ubuntu
git clone $APP_REPO app
chown -R ubuntu:ubuntu app
cd app

# Build your Go app
apt-get install -y golang-go

# Set up Go environment with proper permissions
mkdir -p /home/ubuntu/go/pkg/mod/cache
chown -R ubuntu:ubuntu /home/ubuntu/go

# Build as ubuntu user with proper environment
sudo -u ubuntu bash -c 'export GOPATH=/home/ubuntu/go && export GOMODCACHE=/home/ubuntu/go/pkg/mod && export PATH=/usr/bin:\$PATH && cd /home/ubuntu/app && go mod download && go build -o app .'

# Create K3s Deployment and Service for the Go app
cat <<YAML | /usr/local/bin/kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: haileysgarden-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: haileysgarden
  template:
    metadata:
      labels:
        app: haileysgarden
    spec:
      containers:
      - name: haileysgarden
        image: golang:1.22
        command: ["/home/ubuntu/app/app"]
        ports:
        - containerPort: $APP_PORT
---
apiVersion: v1
kind: Service
metadata:
  name: haileysgarden-service
spec:
  type: NodePort
  selector:
    app: haileysgarden
  ports:
  - port: 80
    targetPort: $APP_PORT
    nodePort: 30080
YAML

# Enable forwarding from port 80 to app
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080

echo "🌼 Hailey's Garden Go app deployed and accessible via port 80"
EOF
)

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

echo ""
echo "✅ K3s + Go App Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Instance ID:  $INSTANCE_ID"
echo "Public IP:    $PUBLIC_IP"
echo "App URL:      http://${PUBLIC_IP}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Instance info saved to ec2-instance-info.txt"
cat > ec2-instance-info.txt <<EOF
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
App URL: http://${PUBLIC_IP}
SSH Command: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP}
Region: $REGION
EOF
