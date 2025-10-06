# Hailey's Garden Kubernetes Deployment

## Architecture

```
Route 53 (haileysgarden.com)
    ↓
AWS Network Load Balancer (with ACM Certificate)
    ↓
NGINX Ingress Controller
    ↓
Egg Shop Service (ClusterIP)
    ↓
Egg Shop Pods (2 replicas)
```

## Features

- ✅ **AWS Load Balancer Controller** - Automatic NLB provisioning
- ✅ **NGINX Ingress** - Advanced routing and SSL termination
- ✅ **ACM Certificate** - Automatic HTTPS with AWS Certificate Manager
- ✅ **Multi-arch Docker images** - Supports AMD64 and ARM64
- ✅ **Health checks** - Liveness and readiness probes
- ✅ **Auto-scaling ready** - Horizontal Pod Autoscaler compatible
- ✅ **Signal API integration** - For order notifications

## Prerequisites

### 1. EKS Cluster or K3s

**For EKS:**
```bash
eksctl create cluster \
  --name haileys-garden \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

**For K3s (EC2):**
```bash
curl -sfL https://get.k3s.io | sh -
```

### 2. AWS Load Balancer Controller (EKS only)

```bash
# Create IAM OIDC provider
eksctl utils associate-iam-oidc-provider \
  --cluster haileys-garden \
  --approve

# Download IAM policy
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=haileys-garden \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::011229313364:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=haileys-garden \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 3. ACM Certificate

Your certificate is already configured:
```
arn:aws:acm:us-east-1:011229313364:certificate/1788d41a-e53e-473e-8579-4c3eed565dea
```

## Deployment

### Quick Deploy

```bash
cd k8s
./deploy.sh
```

### Manual Deploy

```bash
# Apply in order
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmap.yaml
kubectl apply -f 02-secret.yaml
kubectl apply -f 03-deployment.yaml
kubectl apply -f 04-service.yaml
kubectl apply -f 05-signal-api-deployment.yaml
kubectl apply -f 06-nginx-ingress-controller.yaml
kubectl apply -f 07-ingress.yaml
```

## Verify Deployment

### Check all resources
```bash
kubectl get all -n haileys-garden
kubectl get ingress -n haileys-garden
kubectl get svc -n ingress-nginx
```

### Get Load Balancer URL
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Check logs
```bash
# Application logs
kubectl logs -f deployment/egg-shop -n haileys-garden

# NGINX Ingress logs
kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx

# Signal API logs
kubectl logs -f deployment/signal-api -n haileys-garden
```

## Route 53 Configuration

1. Get the Load Balancer hostname:
```bash
LB_HOSTNAME=$(kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $LB_HOSTNAME
```

2. Create/Update Route 53 A record (ALIAS):
   - **Name**: `haileysgarden.com`
   - **Type**: A - IPv4 address
   - **Alias**: Yes
   - **Alias Target**: `$LB_HOSTNAME` (the NLB hostname)
   - **Routing Policy**: Simple

3. Create www subdomain (optional):
   - **Name**: `www.haileysgarden.com`
   - **Type**: CNAME
   - **Value**: `haileysgarden.com`

## Scaling

### Manual scaling
```bash
kubectl scale deployment/egg-shop --replicas=3 -n haileys-garden
```

### Auto-scaling (HPA)
```bash
kubectl autoscale deployment egg-shop \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n haileys-garden
```

## Troubleshooting

### Pod not starting
```bash
kubectl describe pod -l app=egg-shop -n haileys-garden
kubectl logs -l app=egg-shop -n haileys-garden
```

### Ingress not working
```bash
kubectl describe ingress egg-shop-ingress -n haileys-garden
kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx
```

### Load Balancer not provisioned
```bash
# Check AWS Load Balancer Controller logs (EKS only)
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system
```

### Certificate issues
```bash
# Verify certificate ARN in service annotation
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml | grep certificate
```

## Updating the Application

### Update Docker image
```bash
# Build and push new image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t zealousidealowl/haileys-garden:latest --push .

# Restart deployment
kubectl rollout restart deployment/egg-shop -n haileys-garden

# Watch rollout status
kubectl rollout status deployment/egg-shop -n haileys-garden
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace haileys-garden
kubectl delete namespace ingress-nginx

# Or delete individually
kubectl delete -f 07-ingress.yaml
kubectl delete -f 06-nginx-ingress-controller.yaml
kubectl delete -f 05-signal-api-deployment.yaml
kubectl delete -f 04-service.yaml
kubectl delete -f 03-deployment.yaml
kubectl delete -f 02-secret.yaml
kubectl delete -f 01-configmap.yaml
kubectl delete -f 00-namespace.yaml
```

## Architecture Benefits

1. **Automatic HTTPS** - ACM certificate managed by AWS
2. **High Availability** - Multi-replica deployment with health checks
3. **Scalability** - Easy horizontal scaling with HPA
4. **Security** - SSL termination at load balancer, secrets management
5. **Cost Effective** - NLB with instance targets (cheaper than IP targets)
6. **Production Ready** - Industry-standard NGINX Ingress with AWS integration

## Monitoring

### Metrics
```bash
# Install metrics-server (if not already installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View resource usage
kubectl top pods -n haileys-garden
kubectl top nodes
```

### Health checks
```bash
# Check endpoint health
curl -I https://haileysgarden.com/

# Check NGINX Ingress health
kubectl get pods -n ingress-nginx
```

## Support

For issues or questions:
- Check logs: `kubectl logs -f deployment/egg-shop -n haileys-garden`
- Describe resources: `kubectl describe ingress egg-shop-ingress -n haileys-garden`
- Check events: `kubectl get events -n haileys-garden --sort-by='.lastTimestamp'`
