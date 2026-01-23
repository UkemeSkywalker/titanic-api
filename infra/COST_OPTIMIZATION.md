# Cost Optimization Guide

## Current Cost Estimates

### Development Environment
| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| EKS Cluster | Control Plane | $73 |
| EC2 (Nodes) | 2x t3.small | $30 |
| RDS | db.t3.micro | $15 |
| NAT Gateway | Single AZ | $32 |
| ALB | Application LB | $16 |
| Data Transfer | ~100GB | $9 |
| **Total** | | **~$175/month** |

### Production Environment
| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| EKS Cluster | Control Plane | $73 |
| EC2 (Nodes) | 3x t3.medium | $95 |
| RDS | db.t3.medium Multi-AZ | $120 |
| NAT Gateway | Single AZ | $32 |
| ALB | Application LB | $16 |
| Data Transfer | ~500GB | $45 |
| Backups | 30-day retention | $20 |
| **Total** | | **~$401/month** |

## Cost Reduction Strategies

### 1. Use Spot Instances (Save 70%)

```hcl
# modules/eks/main.tf
resource "aws_eks_node_group" "spot" {
  capacity_type = "SPOT"
  instance_types = ["t3.small", "t3a.small", "t2.small"]
  
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }
}
```

**Savings**: ~$21/month (dev), ~$66/month (prod)

### 2. Schedule Shutdown for Non-Prod

```bash
# Stop dev environment at night
aws eks update-nodegroup-config \
  --cluster-name dev-eks \
  --nodegroup-name dev-node-group \
  --scaling-config minSize=0,maxSize=3,desiredSize=0

# Stop RDS
aws rds stop-db-instance --db-instance-identifier dev-titanicdb
```

**Savings**: ~$100/month (60% uptime)

### 3. Use Reserved Instances (Save 40%)

For production workloads with predictable usage:
- 1-year commitment: 40% savings
- 3-year commitment: 60% savings

**Savings**: ~$38/month (prod nodes)

### 4. Optimize RDS

```hcl
# Use Aurora Serverless v2 for variable workloads
resource "aws_rds_cluster" "main" {
  engine_mode = "provisioned"
  engine      = "aurora-postgresql"
  
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }
}
```

**Savings**: ~$40/month (pay per use)

### 5. Use S3 Gateway Endpoint (Free)

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids = [aws_route_table.private.id]
}
```

**Savings**: Data transfer costs

### 6. Enable Compute Savings Plans

```bash
aws savingsplans create-savings-plan \
  --savings-plan-type ComputeSavingsPlans \
  --commitment 50 \
  --upfront-payment-amount 0
```

**Savings**: Up to 66% on compute

### 7. Optimize Data Transfer

- Use CloudFront for static assets
- Enable VPC endpoints for AWS services
- Compress responses
- Use same-region resources

**Savings**: ~$20/month

### 8. Right-Size Resources

```bash
# Analyze actual usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-31T23:59:59Z \
  --period 3600 \
  --statistics Average
```

If CPU < 40%, downsize instance type.

### 9. Use Fargate for Batch Jobs

```hcl
resource "aws_eks_fargate_profile" "batch" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "batch-jobs"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  
  selector {
    namespace = "batch"
  }
}
```

**Savings**: Pay only when jobs run

### 10. Implement Auto-Scaling

```yaml
# HPA already configured in k8s/deployment.yaml
# Also add Cluster Autoscaler
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
```

**Savings**: Scale down during low traffic

## Monitoring Costs

### Enable Cost Explorer

```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

### Set Budget Alerts

```bash
aws budgets create-budget \
  --account-id 123456789012 \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

### Use AWS Cost Anomaly Detection

```bash
aws ce create-anomaly-monitor \
  --anomaly-monitor Name=TitanicAPIMonitor,MonitorType=DIMENSIONAL
```

## Cost Optimization Checklist

- [ ] Enable Spot Instances for dev/staging
- [ ] Schedule shutdown for non-prod (nights/weekends)
- [ ] Purchase Reserved Instances for prod
- [ ] Implement auto-scaling (HPA + Cluster Autoscaler)
- [ ] Right-size instances based on metrics
- [ ] Use S3 Gateway Endpoint
- [ ] Enable RDS storage auto-scaling
- [ ] Delete unused snapshots (>30 days)
- [ ] Use CloudWatch Logs retention policies
- [ ] Enable S3 Intelligent-Tiering
- [ ] Review and delete unused EBS volumes
- [ ] Implement tagging strategy for cost allocation

## Monthly Review Process

1. Review Cost Explorer dashboard
2. Analyze top 5 cost drivers
3. Check for unused resources
4. Validate auto-scaling effectiveness
5. Update cost projections
6. Implement optimization recommendations

## Target Costs After Optimization

- **Development**: $75/month (57% reduction)
- **Production**: $250/month (38% reduction)
- **Total Savings**: ~$250/month
