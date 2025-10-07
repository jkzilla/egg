# Hailey's Garden Helm Chart

A Helm chart for deploying Hailey's Garden egg shop with Signal API notifications and NGINX Ingress.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- NGINX Ingress Controller (or set `nginxIngress.enabled=true`)
- AWS ACM Certificate (for HTTPS)

## Installation

### Install with default values

```bash
helm install haileys-garden ./helm/haileys-garden --namespace haileys-garden --create-namespace
```

### Install with custom values

```bash
helm install haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --create-namespace \
  --set image.tag=v1.0.0 \
  --set replicaCount=3 \
  --set config.signalNumber="+1234567890"
```

### Install with values file

```bash
helm install haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --create-namespace \
  --values custom-values.yaml
```

## Upgrading

```bash
helm upgrade haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --values custom-values.yaml
```

## Uninstalling

```bash
helm uninstall haileys-garden --namespace haileys-garden
```

## Configuration

The following table lists the configurable parameters and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `zealousidealowl/haileys-garden` |
| `image.tag` | Image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `8080` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts` | Ingress hosts | `[haileysgarden.com, www.haileysgarden.com]` |
| `signalApi.enabled` | Enable Signal API | `true` |
| `config.signalNumber` | Signal phone number | `+17073243359` |
| `config.ownerPhoneNumber` | Owner phone number | `+17073243359` |

## Examples

### Production deployment with 3 replicas

```yaml
# production-values.yaml
replicaCount: 3

image:
  tag: "v1.0.0"
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 1000m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi

ingress:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "200"
```

```bash
helm install haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --create-namespace \
  --values production-values.yaml
```

### Development deployment

```yaml
# dev-values.yaml
replicaCount: 1

image:
  tag: "latest"
  pullPolicy: Always

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

ingress:
  hosts:
    - host: dev.haileysgarden.com
      paths:
        - path: /
          pathType: Prefix
```

## Deploying to K3s/EC2

1. **Install Helm** (if not already installed):
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

2. **Install NGINX Ingress Controller**:
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

3. **Deploy Hailey's Garden**:
```bash
helm install haileys-garden ./helm/haileys-garden \
  --namespace haileys-garden \
  --create-namespace
```

4. **Check deployment status**:
```bash
helm status haileys-garden -n haileys-garden
kubectl get all -n haileys-garden
```

## Troubleshooting

### View Helm release history
```bash
helm history haileys-garden -n haileys-garden
```

### Rollback to previous version
```bash
helm rollback haileys-garden -n haileys-garden
```

### Debug rendering
```bash
helm template haileys-garden ./helm/haileys-garden --debug
```

### View actual values
```bash
helm get values haileys-garden -n haileys-garden
```

## Architecture

```
Route 53
    ↓
AWS NLB (with ACM Certificate)
    ↓
NGINX Ingress Controller
    ↓
Hailey's Garden Service (ClusterIP)
    ↓
Hailey's Garden Pods (2 replicas)
    ↓
Signal API Service
    ↓
Signal API Pod
```

## Benefits of Helm

1. **Templating** - Reusable configurations across environments
2. **Versioning** - Track changes and rollback easily
3. **Dependency Management** - Manage related charts
4. **Values Override** - Easy configuration per environment
5. **Hooks** - Pre/post install/upgrade actions
6. **Packaging** - Distribute as a single artifact
7. **Release Management** - Track deployments and history

## License

MIT
