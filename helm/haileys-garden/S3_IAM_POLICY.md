# S3 IAM Policy for TruffleHog Enterprise

## Overview

TruffleHog Enterprise needs IAM permissions to:
1. Scan S3 buckets for secrets
2. Store scan results in S3
3. Backup PostgreSQL database to S3

## IAM Policy

Create this IAM policy and attach it to your EKS service account or EC2 instance role.

### Policy JSON

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ScanBuckets",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::haileys-garden-logs",
        "arn:aws:s3:::haileys-garden-logs/*",
        "arn:aws:s3:::haileys-garden-backups",
        "arn:aws:s3:::haileys-garden-backups/*"
      ]
    },
    {
      "Sid": "StoreResults",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::trufflehog-scan-results",
        "arn:aws:s3:::trufflehog-scan-results/*"
      ]
    },
    {
      "Sid": "DatabaseBackups",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::trufflehog-db-backups",
        "arn:aws:s3:::trufflehog-db-backups/*"
      ]
    }
  ]
}
```

## Setup Instructions

### Option 1: EKS with IRSA (Recommended)

1. **Create IAM Policy**

```bash
aws iam create-policy \
  --policy-name TruffleHogS3Access \
  --policy-document file://trufflehog-s3-policy.json
```

2. **Create IAM Role for Service Account**

```bash
eksctl create iamserviceaccount \
  --name haileys-garden-trufflehog-sa \
  --namespace haileys-garden \
  --cluster your-cluster-name \
  --attach-policy-arn arn:aws:iam::011229313364:policy/TruffleHogS3Access \
  --approve \
  --override-existing-serviceaccounts
```

3. **Update values.yaml**

```yaml
trufflehog:
  config:
    s3:
      serviceAccount:
        create: true
        annotations:
          eks.amazonaws.com/role-arn: arn:aws:iam::011229313364:role/eksctl-your-cluster-addon-iamserviceaccount-Role
```

### Option 2: EC2 Instance Role (K3s)

1. **Create IAM Policy**

```bash
aws iam create-policy \
  --policy-name TruffleHogS3Access \
  --policy-document file://trufflehog-s3-policy.json
```

2. **Attach to EC2 Instance Role**

```bash
# Get instance profile
aws ec2 describe-instances \
  --instance-ids i-your-instance-id \
  --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn'

# Attach policy
aws iam attach-role-policy \
  --role-name your-ec2-role \
  --policy-arn arn:aws:iam::011229313364:policy/TruffleHogS3Access
```

3. **No ServiceAccount needed**

```yaml
trufflehog:
  config:
    s3:
      serviceAccount:
        create: false
```

## Create S3 Buckets

```bash
# Scan results bucket
aws s3 mb s3://trufflehog-scan-results --region us-east-1

# Database backups bucket
aws s3 mb s3://trufflehog-db-backups --region us-east-1

# Enable versioning for backups
aws s3api put-bucket-versioning \
  --bucket trufflehog-db-backups \
  --versioning-configuration Status=Enabled

# Lifecycle policy to delete old backups
aws s3api put-bucket-lifecycle-configuration \
  --bucket trufflehog-db-backups \
  --lifecycle-configuration file://lifecycle-policy.json
```

### Lifecycle Policy (lifecycle-policy.json)

```json
{
  "Rules": [
    {
      "Id": "DeleteOldBackups",
      "Status": "Enabled",
      "Prefix": "",
      "Expiration": {
        "Days": 30
      },
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 7
      }
    }
  ]
}
```

## Verify Setup

### Test S3 Access from Pod

```bash
# Get pod name
kubectl get pods -n haileys-garden -l app.kubernetes.io/component=trufflehog

# Test S3 access
kubectl exec -it <pod-name> -n haileys-garden -- sh

# Inside pod
apk add --no-cache aws-cli
aws s3 ls s3://trufflehog-scan-results/
aws s3 ls s3://haileys-garden-logs/
```

### Check ServiceAccount Annotations

```bash
kubectl get sa haileys-garden-trufflehog-sa -n haileys-garden -o yaml
```

Should see:
```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::011229313364:role/...
```

## Troubleshooting

### Access Denied Errors

1. **Check IAM policy is attached**

```bash
aws iam list-attached-role-policies --role-name your-role-name
```

2. **Verify bucket names match**

```bash
# In values.yaml
s3:
  scanBuckets:
    - name: haileys-garden-logs  # Must match IAM policy
```

3. **Check pod logs**

```bash
kubectl logs -f deployment/haileys-garden-trufflehog -n haileys-garden
```

### Backup CronJob Failures

```bash
# Check CronJob
kubectl get cronjobs -n haileys-garden

# Check last job
kubectl get jobs -n haileys-garden

# View logs
kubectl logs job/haileys-garden-trufflehog-backup-<timestamp> -n haileys-garden
```

## Security Best Practices

1. **Use least privilege** - Only grant access to specific buckets
2. **Enable bucket encryption** - Use SSE-S3 or SSE-KMS
3. **Enable versioning** - For backup buckets
4. **Use VPC endpoints** - For S3 access without internet
5. **Monitor access** - Enable CloudTrail logging

## Cost Optimization

1. **Use S3 Intelligent-Tiering** for scan results
2. **Set lifecycle policies** to delete old backups
3. **Compress backups** before uploading
4. **Use S3 Select** for querying scan results

## Monitoring

### CloudWatch Metrics

```bash
# S3 bucket metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name NumberOfObjects \
  --dimensions Name=BucketName,Value=trufflehog-scan-results \
  --start-time 2025-10-01T00:00:00Z \
  --end-time 2025-10-14T00:00:00Z \
  --period 86400 \
  --statistics Average
```

### S3 Storage Usage

```bash
# Check bucket size
aws s3 ls s3://trufflehog-scan-results --recursive --summarize | grep "Total Size"
```

## Resources

- [EKS IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [S3 IAM Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-iam-policies.html)
- [S3 Lifecycle Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
