# Disaster Recovery Plan

## Overview

This document outlines the disaster recovery procedures for the Titanic API infrastructure.

## Recovery Objectives

- **RTO** (Recovery Time Objective): < 1 hour
- **RPO** (Recovery Point Objective): < 5 minutes

## Backup Strategy

### Database Backups
- **Automated**: Daily snapshots with 7-30 day retention
- **Manual**: On-demand snapshots before major changes
- **Cross-region**: Enabled for production (us-east-1 → us-west-2)

### Infrastructure Backups
- **Terraform State**: S3 with versioning enabled
- **Configuration**: Git repository (version controlled)
- **Secrets**: AWS Secrets Manager with recovery window

## Recovery Procedures

### 1. Database Recovery

#### Restore from Snapshot
```bash
# List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier prod-titanicdb

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-titanicdb-restored \
  --db-snapshot-identifier rds:prod-titanicdb-2024-01-01-00-00

# Update DNS/connection string
aws secretsmanager update-secret \
  --secret-id prod/titanic/database \
  --secret-string '{"host":"new-endpoint",...}'
```

#### Point-in-Time Recovery
```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-titanicdb \
  --target-db-instance-identifier prod-titanicdb-pitr \
  --restore-time 2024-01-01T12:00:00Z
```

### 2. EKS Cluster Recovery

#### Full Cluster Recreation
```bash
cd infra
terraform workspace select prod
terraform apply -var-file=environments/prod/terraform.tfvars

# Update kubeconfig
aws eks update-kubeconfig --name prod-eks --region us-east-1

# Redeploy application
./scripts/deploy-app.sh prod
```

#### Node Group Recovery
```bash
# Drain nodes
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Terraform recreate
terraform taint module.eks.aws_eks_node_group.main
terraform apply
```

### 3. Complete Region Failure

#### Failover to Secondary Region
```bash
# Deploy to secondary region
cd infra
terraform workspace select prod-dr
terraform apply -var-file=environments/prod/terraform.tfvars -var="aws_region=us-west-2"

# Restore database from cross-region snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-titanicdb \
  --db-snapshot-identifier arn:aws:rds:us-west-2:...:snapshot:prod-snapshot \
  --region us-west-2

# Update DNS to point to new region
aws route53 change-resource-record-sets --hosted-zone-id Z123 --change-batch file://failover.json
```

### 4. Secrets Recovery

```bash
# Restore deleted secret (within recovery window)
aws secretsmanager restore-secret --secret-id prod/titanic/database

# Recreate from backup
aws secretsmanager create-secret \
  --name prod/titanic/database \
  --secret-string file://backup-secret.json
```

## Testing Schedule

- **Monthly**: Database restore test (non-prod)
- **Quarterly**: Full DR drill (secondary region)
- **Annually**: Complete disaster simulation

## Monitoring & Alerts

### Critical Alerts
- RDS backup failures
- EKS node failures (>50%)
- Application downtime (>5 minutes)
- State lock issues

### CloudWatch Alarms
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name prod-rds-backup-failed \
  --alarm-description "RDS backup failed" \
  --metric-name BackupRetentionPeriodStorageUsed \
  --namespace AWS/RDS \
  --statistic Average \
  --period 86400 \
  --threshold 0 \
  --comparison-operator LessThanThreshold
```

## Contact Information

- **On-Call Engineer**: [PagerDuty/Slack]
- **AWS Support**: Enterprise Support Plan
- **Escalation**: [Team Lead Contact]

## Post-Incident

1. Document incident timeline
2. Update runbooks
3. Conduct blameless postmortem
4. Implement preventive measures
5. Test recovery procedures
