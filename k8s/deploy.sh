#!/bin/bash
set -e

echo "🚀 Deploying Hailey's Garden Egg Shop to K3s..."

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t egg:latest .

# Import image to K3s
echo "📥 Importing image to K3s..."
docker save egg:latest | sudo k3s ctr images import -

# Apply Kubernetes manifests
echo "☸️  Applying Kubernetes manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/signal-api-deployment.yaml
kubectl apply -f k8s/egg-deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/signal-api -n haileys-garden
kubectl wait --for=condition=available --timeout=300s deployment/egg-shop -n haileys-garden

# Get service info
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Service Status:"
kubectl get all -n haileys-garden
echo ""
echo "🌐 Access the application:"
echo "   LoadBalancer: kubectl get svc egg-shop -n haileys-garden"
echo "   Port Forward: kubectl port-forward -n haileys-garden svc/egg-shop 3000:80"
echo ""
echo "📱 Signal API QR Code (for linking):"
echo "   kubectl port-forward -n haileys-garden svc/signal-api 8080:8080"
echo "   Then visit: http://localhost:8080/v1/qrcodelink?device_name=haileys-garden"
