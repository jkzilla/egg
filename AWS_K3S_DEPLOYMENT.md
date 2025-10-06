# Deploy Hailey's Garden to AWS EC2 with K3s (Free Tier)

This guide shows how to deploy the egg shop on a free AWS t2.micro EC2 instance running K3s.

## Prerequisites

- AWS Account (Free Tier eligible)
- SSH key pair for EC2
- Domain name (optional, for custom domain)

## Step 1: Launch EC2 Instance

### Create t2.micro Instance (Free Tier)

1. **Go to EC2 Console** → Launch Instance
2. **Name**: `haileys-garden-k3s`
3. **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
4. **Instance type**: `t2.micro` (1 vCPU, 1 GB RAM - Free tier)
5. **Key pair**: Create or select existing SSH key
6. **Network settings**:
   - Allow SSH (port 22) from your IP
   - Allow HTTP (port 80) from anywhere (0.0.0.0/0)
   - Allow HTTPS (port 443) from anywhere (0.0.0.0/0)
   - Allow Custom TCP (port 8080) from your IP (for Signal API setup)
7. **Storage**: 30 GB gp3 (Free tier includes 30 GB)
8. **Launch instance**

### Get Instance IP

```bash
# Note your instance's public IP address
# Example: 54.123.45.67
```

## Step 2: Connect and Install K3s

### SSH into Instance

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### Install K3s

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install K3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -

# Check K3s is running
sudo k3s kubectl get nodes

# Set up kubectl access for ubuntu user
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
export KUBECONFIG=~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
```

### Install Docker

```bash
# Install Docker for building images
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu
newgrp docker
```

## Step 3: Deploy Application

### Clone Repository

```bash
git clone https://github.com/jkzilla/egg.git
cd egg
```

### Build and Deploy

```bash
# Build the Docker image
docker build -t egg:latest .

# Import image to K3s
docker save egg:latest | sudo k3s ctr images import -

# Deploy to K3s
sudo k3s kubectl apply -f k8s/namespace.yaml
sudo k3s kubectl apply -f k8s/configmap.yaml
sudo k3s kubectl apply -f k8s/secret.yaml
sudo k3s kubectl apply -f k8s/signal-api-deployment.yaml
sudo k3s kubectl apply -f k8s/egg-deployment.yaml
```

### Check Deployment Status

```bash
sudo k3s kubectl get all -n haileys-garden
```

## Step 4: Set Up Signal API

### Port Forward Signal API

```bash
# On EC2 instance
sudo k3s kubectl port-forward -n haileys-garden svc/signal-api 8080:8080 --address 0.0.0.0 &
```

### Link Signal Device

From your local machine:

```bash
# Visit in browser (replace with your EC2 IP)
http://YOUR_EC2_PUBLIC_IP:8080/v1/qrcodelink?device_name=haileys-garden

# Or download QR code
curl "http://YOUR_EC2_PUBLIC_IP:8080/v1/qrcodelink?device_name=haileys-garden" --output signal-qr.png
```

Scan the QR code with your Signal app (using Google Voice number +17073243359)

## Step 5: Expose Application

### Option A: Using LoadBalancer (K3s default)

K3s includes a built-in load balancer (Klipper):

```bash
# Get the external IP
sudo k3s kubectl get svc egg-shop -n haileys-garden

# Access at: http://YOUR_EC2_PUBLIC_IP
```

### Option B: Using Ingress with Custom Domain

```bash
# Apply ingress
sudo k3s kubectl apply -f k8s/ingress.yaml

# Point your domain to EC2 public IP
# Add A record: haileys-garden.com -> YOUR_EC2_PUBLIC_IP

# Access at: http://haileys-garden.com
```

### Option C: Port Forward for Testing

```bash
sudo k3s kubectl port-forward -n haileys-garden svc/egg-shop 80:80 --address 0.0.0.0
```

## Step 6: Set Up SSL (Optional)

### Install Cert-Manager

```bash
# Install cert-manager
sudo k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
sudo k3s kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
```

### Create Let's Encrypt Issuer

```bash
cat <<EOF | sudo k3s kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
EOF
```

### Update Ingress for SSL

```bash
cat <<EOF | sudo k3s kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: egg-shop-ingress
  namespace: haileys-garden
  annotations:
    kubernetes.io/ingress.class: traefik
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - haileys-garden.com
    secretName: egg-shop-tls
  rules:
  - host: haileys-garden.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: egg-shop
            port:
              number: 80
EOF
```

## Monitoring & Maintenance

### View Logs

```bash
# Application logs
sudo k3s kubectl logs -f deployment/egg-shop -n haileys-garden

# Signal API logs
sudo k3s kubectl logs -f deployment/signal-api -n haileys-garden
```

### Restart Deployment

```bash
sudo k3s kubectl rollout restart deployment/egg-shop -n haileys-garden
```

### Update Application

```bash
cd ~/egg
git pull
docker build -t egg:latest .
docker save egg:latest | sudo k3s ctr images import -
sudo k3s kubectl rollout restart deployment/egg-shop -n haileys-garden
```

## Cost Breakdown (AWS Free Tier)

- ✅ **EC2 t2.micro**: 750 hours/month (FREE for 12 months)
- ✅ **30 GB EBS Storage**: FREE for 12 months
- ✅ **Data Transfer**: 15 GB/month outbound (FREE)
- ✅ **Public IPv4**: $0.005/hour (~$3.60/month) ⚠️ Only cost!

**Total Monthly Cost**: ~$3.60 (just for the public IP)

## Troubleshooting

### Pod not starting

```bash
sudo k3s kubectl describe pod -n haileys-garden
```

### Out of memory

```bash
# Check memory usage
free -h

# Reduce replicas if needed
sudo k3s kubectl scale deployment/egg-shop --replicas=1 -n haileys-garden
```

### Signal API not working

```bash
# Check Signal API logs
sudo k3s kubectl logs deployment/signal-api -n haileys-garden

# Restart Signal API
sudo k3s kubectl rollout restart deployment/signal-api -n haileys-garden
```

## Security Best Practices

1. **Restrict SSH**: Only allow SSH from your IP
2. **Use Security Groups**: Limit port 8080 access to your IP only
3. **Enable UFW Firewall**:
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```
4. **Regular Updates**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

## Backup Signal Data

```bash
# Backup Signal CLI data
sudo k3s kubectl exec -n haileys-garden deployment/signal-api -- tar czf /tmp/signal-backup.tar.gz /home/.local/share/signal-cli
sudo k3s kubectl cp haileys-garden/signal-api-xxx:/tmp/signal-backup.tar.gz ./signal-backup.tar.gz
```

## Resources

- [K3s Documentation](https://docs.k3s.io/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Signal CLI REST API](https://github.com/bbernhard/signal-cli-rest-api)
