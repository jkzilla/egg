#!/bin/bash
set -e

echo "🌼 Deploying Hailey's Garden with AWS Load Balancer + NGINX Ingress"
echo "===================================================================="

# Apply manifests in order
echo "📦 Creating namespace..."
kubectl apply -f 00-namespace.yaml

echo "🔧 Creating ConfigMap and Secrets..."
kubectl apply -f 01-configmap.yaml
kubectl apply -f 02-secret.yaml

echo "🚀 Deploying application..."
kubectl apply -f 03-deployment.yaml
kubectl apply -f 04-service.yaml

echo "📱 Deploying Signal API..."
kubectl apply -f 05-signal-api-deployment.yaml

echo "🔀 Installing NGINX Ingress Controller..."
kubectl apply -f 06-nginx-ingress-controller.yaml

echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "🌐 Creating Ingress..."
kubectl apply -f 07-ingress.yaml

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Check status:"
echo "  kubectl get all -n haileys-garden"
echo "  kubectl get ingress -n haileys-garden"
echo "  kubectl get svc -n ingress-nginx"
echo ""
echo "🔍 Get Load Balancer URL:"
echo "  kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
echo ""
echo "📝 Point your Route 53 domain to the Load Balancer hostname"
