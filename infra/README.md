# Titanic API Infrastructure

Terraform infrastructure for deploying Titanic API on AWS with EKS, RDS, and best practices.

## Architecture

- **VPC**: Multi-AZ with public/private subnets, NAT Gateway
- **EKS**: Kubernetes cluster with auto-scaling node groups
- **RDS**: PostgreSQL with automated backups and encryption
- **ALB**: Application Load Balancer for traffic distribution
- **Secrets Manager**: Secure credential storage
- **IAM**: IRSA (IAM Roles for Service Accounts) for pod-level permissions

## Prerequisites

1. **AWS CLI** configured with credentials
2. **Terraform** >= 1.0
3. **kubectl** for Kubernetes management
4. **AWS Account** with appropriate permissions

## Initial Setup

### 1. Create S3 Backend

```bash
aws s3api create-bucket \
  --bucket titanic-api-terraform-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket titanic-api-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket titanic-api-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 2. Create DynamoDB Lock Table

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Deployment

### Development Environment

```bash
cd infra
terraform init
terraform workspace new dev || terraform workspace select dev
terraform plan -var-file=environments/dev/terraform.tfvars -var="db_password=YOUR_SECURE_PASSWORD"
terraform apply -var-file=environments/dev/terraform.tfvars -var="db_password=YOUR_SECURE_PASSWORD"
```

### Staging Environment

```bash
terraform workspace new staging || terraform workspace select staging
terraform plan -var-file=environments/staging/terraform.tfvars -var="db_password=YOUR_SECURE_PASSWORD"
terraform apply -var-file=environments/staging/terraform.tfvars -var="db_password=YOUR_SECURE_PASSWORD"
```

### Production Environment

```bash
terraform workspace new prod || terraform workspace select prod
terraform plan -var-file=environments/prod/terraform.tfvars -var="db_password=YOUR_SECURE_PASSWORD"
terraform apply -var-file=environments/prod/terraform.tfvars -var="db_password=YOUR_SECURE_PASSWORD"
```

## Connect to EKS Cluster

```bash
aws eks update-kubeconfig --name dev-eks --region us-east-1
kubectl get nodes
```

## Retrieve Database Credentials

```bash
aws secretsmanager get-secret-value \
  --secret-id dev/titanic/database \
  --query SecretString \
  --output text | jq .
```

## Cost Optimization

### Development
- Single NAT Gateway
- t3.small EKS nodes (1-3)
- db.t3.micro RDS
- 7-day backups
- **Estimated**: ~$150-200/month

### Production
- Multi-AZ RDS
- t3.medium EKS nodes (2-5)
- 30-day backups
- Performance Insights enabled
- **Estimated**: ~$400-600/month

### Cost Reduction Tips
1. Use Spot Instances for non-prod
2. Schedule shutdown for dev environments
3. Enable AWS Cost Explorer
4. Use Reserved Instances for prod

## Disaster Recovery

### Backup Strategy
- **RDS**: Automated daily backups (7-30 days retention)
- **EKS**: GitOps approach (infrastructure as code)
- **Secrets**: Secrets Manager with recovery window

### Recovery Procedures

#### Database Recovery
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-titanicdb-restored \
  --db-snapshot-identifier prod-snapshot-2024-01-01
```

#### Full Environment Recovery
```bash
terraform workspace select prod
terraform apply -var-file=environments/prod/terraform.tfvars
```

### RTO/RPO
- **RTO** (Recovery Time Objective): < 1 hour
- **RPO** (Recovery Point Objective): < 5 minutes (automated backups)

## Security Best Practices

✅ Encryption at rest (RDS, EBS)  
✅ Encryption in transit (TLS)  
✅ Private subnets for workloads  
✅ Security groups with least privilege  
✅ IAM roles with minimal permissions  
✅ Secrets Manager for credentials  
✅ VPC Flow Logs enabled  
✅ CloudWatch logging enabled  
✅ No hardcoded credentials  

## Monitoring

### CloudWatch Dashboards
```bash
aws cloudwatch get-dashboard --dashboard-name titanic-api-prod
```

### Key Metrics
- EKS node CPU/Memory utilization
- RDS connections and query performance
- ALB request count and latency
- Application logs in CloudWatch Logs

## Cleanup

```bash
# Destroy environment
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars -var="db_password=dummy"

# Delete workspace
terraform workspace select default
terraform workspace delete dev
```

## Troubleshooting

### EKS Connection Issues
```bash
aws eks describe-cluster --name dev-eks --query cluster.status
aws eks update-kubeconfig --name dev-eks --region us-east-1
```

### RDS Connection Issues
```bash
aws rds describe-db-instances --db-instance-identifier dev-titanicdb
# Check security groups allow traffic from EKS nodes
```

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

## Module Structure

```
infra/
├── main.tf                 # Root module
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── modules/
│   ├── vpc/               # VPC, subnets, NAT, ALB
│   ├── eks/               # EKS cluster and node groups
│   ├── rds/               # PostgreSQL database
│   ├── iam/               # IAM roles and policies
│   └── secrets/           # Secrets Manager
└── environments/
    ├── dev/               # Development config
    ├── staging/           # Staging config
    └── prod/              # Production config
```

## Support

For issues or questions:
1. Check CloudWatch Logs
2. Review Terraform state: `terraform show`
3. Validate configuration: `terraform validate`
4. Check AWS Service Health Dashboard
