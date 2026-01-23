# Quick Start Guide

## Prerequisites

```bash
# Install required tools
brew install terraform awscli kubectl

# Configure AWS credentials
aws configure
```

## 5-Minute Setup

### 1. Setup Backend (One-time)

```bash
cd infra
./scripts/setup-backend.sh
```

### This automatically:
- Creates S3 bucket with your AWS account ID: `titanic-api-terraform-state-{ACCOUNT_ID}`
- Creates DynamoDB table for state locking
- Generates `backend.tf` with correct bucket name
- No manual configuration needed!

### 2. Deploy Infrastructure

```bash
# Development
./deploy.sh dev apply

# Production
./deploy.sh prod apply
```

### 3. Connect to Cluster

```bash
aws eks update-kubeconfig --name dev-eks --region us-east-1
kubectl get nodes
```

### 4. Deploy Application

```bash
./scripts/deploy-app.sh dev
```

### 5. Test API

```bash
# Get load balancer URL
kubectl get svc titanic-api -n dev

# Test endpoint
curl http://<LOAD_BALANCER_URL>/people
```

## Common Commands

```bash
# View infrastructure
terraform show

# Get outputs
terraform output

# Get database credentials
aws secretsmanager get-secret-value --secret-id dev/titanic/database | jq -r .SecretString

# View logs
kubectl logs -f deployment/titanic-api -n dev

# Scale application
kubectl scale deployment titanic-api --replicas=5 -n dev

# Destroy environment
./deploy.sh dev destroy
```

## Troubleshooting

### Can't connect to EKS
```bash
aws eks update-kubeconfig --name dev-eks --region us-east-1
kubectl config current-context
```

### Database connection failed
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier dev-titanicdb

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxx
```

### Terraform state locked
```bash
# List locks
aws dynamodb scan --table-name terraform-state-lock

# Force unlock (caution!)
terraform force-unlock <LOCK_ID>
```

## Next Steps

- Review [README.md](README.md) for detailed documentation
- Check [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md) for cost savings
- Read [SECURITY.md](SECURITY.md) for security best practices
- Review [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md) for DR procedures
