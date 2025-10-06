#!/bin/bash
set -e

EC2_IP="54.90.96.195"
SSH_KEY="~/.ssh/haileys-garden-key.pem"

echo "🚀 Deploying Hailey's Garden to EC2 K3s cluster..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Copy files to EC2
echo "📦 Copying application files to EC2..."
ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$EC2_IP "mkdir -p ~/egg"
scp -i $SSH_KEY -r -o StrictHostKeyChecking=no \
    Dockerfile \
    go.mod \
    go.sum \
    main.go \
    server.go \
    tools.go \
    gqlgen.yml \
    graph/ \
    signal/ \
    frontend/ \
    k8s/ \
    ubuntu@$EC2_IP:~/egg/

echo "✅ Files copied"

# Step 2: Install K3s and dependencies
echo "🔧 Installing K3s and Docker on EC2..."
ssh -i $SSH_KEY ubuntu@$EC2_IP 'bash -s' << 'ENDSSH'
set -e

echo "📦 Updating system..."
sudo apt update -qq

echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu

echo "☸️  Installing K3s..."
curl -sfL https://get.k3s.io | sh -

echo "🔑 Setting up kubectl access..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
export KUBECONFIG=~/.kube/config

echo "✅ K3s installed successfully"
ENDSSH

echo "✅ K3s and Docker installed"

# Step 3: Build and deploy application
echo "🏗️  Building and deploying application..."
ssh -i $SSH_KEY ubuntu@$EC2_IP 'bash -s' << 'ENDSSH'
set -e

cd ~/egg
export KUBECONFIG=~/.kube/config

echo "🐳 Building Docker image..."
docker build -t egg:latest .

echo "📥 Importing image to K3s..."
docker save egg:latest | sudo k3s ctr images import -

echo "☸️  Deploying to Kubernetes..."
sudo k3s kubectl apply -f k8s/namespace.yaml
sudo k3s kubectl apply -f k8s/configmap.yaml
sudo k3s kubectl apply -f k8s/secret.yaml
sudo k3s kubectl apply -f k8s/signal-api-deployment.yaml
sudo k3s kubectl apply -f k8s/egg-deployment.yaml

echo "⏳ Waiting for deployments to be ready..."
sudo k3s kubectl wait --for=condition=available --timeout=300s deployment/signal-api -n haileys-garden || true
sudo k3s kubectl wait --for=condition=available --timeout=300s deployment/egg-shop -n haileys-garden || true

echo "✅ Deployment complete!"
echo ""
echo "📊 Deployment Status:"
sudo k3s kubectl get all -n haileys-garden
ENDSSH

echo ""
echo "✅ Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Your application is now running at:"
echo "   http://$EC2_IP"
echo "   http://haileysgarden.com (once DNS propagates)"
echo ""
echo "📱 To link Signal API:"
echo "   1. Port forward Signal API:"
echo "      ssh -i $SSH_KEY -L 8080:localhost:8080 ubuntu@$EC2_IP"
echo "   2. In another terminal, get QR code:"
echo "      curl http://localhost:8080/v1/qrcodelink?device_name=haileys-garden --output signal-qr.png && open signal-qr.png"
echo "   3. Scan with Signal app (using +17073243359)"
echo ""
echo "📝 Useful commands:"
echo "   SSH to instance:"
echo "      ssh -i $SSH_KEY ubuntu@$EC2_IP"
echo ""
echo "   View logs:"
echo "      ssh -i $SSH_KEY ubuntu@$EC2_IP 'sudo k3s kubectl logs -f deployment/egg-shop -n haileys-garden'"
echo ""
echo "   Check status:"
echo "      ssh -i $SSH_KEY ubuntu@$EC2_IP 'sudo k3s kubectl get all -n haileys-garden'"
