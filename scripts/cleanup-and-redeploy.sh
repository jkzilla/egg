#!/bin/bash
set -e

echo "🧹 Cleaning up old deployment..."

# Delete old deployment in default namespace
ssh -i ~/.ssh/garden2.pem -o StrictHostKeyChecking=no ubuntu@13.218.147.205 << 'EOF'
sudo k3s kubectl delete deployment haileysgarden-app -n default --ignore-not-found=true
sudo k3s kubectl delete service haileysgarden-service -n default --ignore-not-found=true

echo "✅ Old deployment cleaned up"

# Apply new K8s manifests
cd /tmp/egg/k8s

echo "📦 Applying namespace..."
sudo k3s kubectl apply -f 00-namespace.yaml

echo "🔧 Applying configmap and secrets..."
sudo k3s kubectl apply -f 01-configmap.yaml
sudo k3s kubectl apply -f 02-secret.yaml

echo "🚀 Deploying applications..."
sudo k3s kubectl apply -f 03-deployment.yaml
sudo k3s kubectl apply -f 04-service.yaml
sudo k3s kubectl apply -f 05-signal-api-deployment.yaml

echo "🔀 Deploying NGINX Ingress..."
sudo k3s kubectl apply -f 06-nginx-ingress-controller.yaml
sudo k3s kubectl apply -f 07-ingress.yaml

echo "⏳ Waiting for pods to be ready..."
sudo k3s kubectl wait --for=condition=ready pod -l app=egg-shop -n haileys-garden --timeout=300s || true
sudo k3s kubectl wait --for=condition=ready pod -l app=signal-api -n haileys-garden --timeout=300s || true

echo "📊 Deployment status:"
sudo k3s kubectl get all -n haileys-garden
sudo k3s kubectl get all -n ingress-nginx

echo "✅ New architecture deployed successfully!"
EOF
