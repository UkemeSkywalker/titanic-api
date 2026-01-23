# Security Best Practices

## Infrastructure Security

### Network Security
✅ **Private Subnets**: All workloads run in private subnets  
✅ **NAT Gateway**: Outbound internet access without exposing instances  
✅ **Security Groups**: Least privilege access rules  
✅ **Network ACLs**: Additional layer of network security  

### Encryption
✅ **At Rest**: RDS encryption, EBS encryption, S3 encryption  
✅ **In Transit**: TLS/SSL for all communications  
✅ **Secrets**: AWS Secrets Manager with automatic rotation  

### Access Control
✅ **IAM Roles**: No long-term credentials  
✅ **IRSA**: Pod-level IAM permissions  
✅ **MFA**: Required for production access  
✅ **Least Privilege**: Minimal permissions granted  

## Compliance Checklist

### CIS AWS Foundations Benchmark

- [ ] Enable CloudTrail in all regions
- [ ] Enable Config in all regions
- [ ] Enable GuardDuty
- [ ] Enable Security Hub
- [ ] Rotate IAM access keys every 90 days
- [ ] Enable MFA for root account
- [ ] No root account access keys
- [ ] Password policy enforced
- [ ] S3 buckets not publicly accessible
- [ ] VPC flow logs enabled

### Implementation

```bash
# Enable CloudTrail
aws cloudtrail create-trail \
  --name titanic-api-trail \
  --s3-bucket-name titanic-api-cloudtrail

# Enable GuardDuty
aws guardduty create-detector --enable

# Enable Security Hub
aws securityhub enable-security-hub

# Enable Config
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT:role/config-role

# Enable VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-xxx \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs
```

## Secrets Management

### Never Commit Secrets
```bash
# Use git-secrets to prevent commits
git secrets --install
git secrets --register-aws
```

### Rotate Credentials
```bash
# Enable automatic rotation
aws secretsmanager rotate-secret \
  --secret-id prod/titanic/database \
  --rotation-lambda-arn arn:aws:lambda:...
```

### Access Secrets in Application
```python
import boto3
import json

def get_secret():
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='prod/titanic/database')
    return json.loads(response['SecretString'])
```

## Container Security

### Image Scanning
```bash
# Scan with Trivy
trivy image ghcr.io/username/titanic-api:latest

# Scan with AWS ECR
aws ecr start-image-scan --repository-name titanic-api --image-id imageTag=latest
```

### Non-Root User
```dockerfile
# Already implemented in Dockerfile
USER appuser
```

### Minimal Base Image
```dockerfile
FROM python:3.11-slim  # Not alpine or full
```

## Kubernetes Security

### Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: titanic-api-netpol
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: titanic-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: prod
    ports:
    - protocol: TCP
      port: 5000
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 5432  # RDS
```

### RBAC
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: titanic-api-role
  namespace: prod
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: titanic-api-binding
  namespace: prod
subjects:
- kind: ServiceAccount
  name: titanic-api
roleRef:
  kind: Role
  name: titanic-api-role
  apiGroup: rbac.authorization.k8s.io
```

## Monitoring & Logging

### Enable Audit Logs
```hcl
# Already enabled in modules/eks/main.tf
enabled_cluster_log_types = ["api", "audit", "authenticator"]
```

### CloudWatch Logs Retention
```bash
aws logs put-retention-policy \
  --log-group-name /aws/eks/prod-eks/cluster \
  --retention-in-days 90
```

### Security Monitoring
```bash
# CloudWatch Insights query for failed auth
aws logs start-query \
  --log-group-name /aws/eks/prod-eks/cluster \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /Forbidden/'
```

## Incident Response

### 1. Detection
- GuardDuty alerts
- Security Hub findings
- CloudWatch alarms
- Application logs

### 2. Containment
```bash
# Isolate compromised instance
aws ec2 modify-instance-attribute \
  --instance-id i-xxx \
  --groups sg-isolated

# Revoke IAM credentials
aws iam update-access-key \
  --access-key-id AKIA... \
  --status Inactive
```

### 3. Investigation
```bash
# Review CloudTrail logs
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=compromised-user

# Analyze VPC Flow Logs
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs \
  --filter-pattern '[version, account, eni, source, destination, srcport, destport="22", protocol="6", packets, bytes, windowstart, windowend, action="ACCEPT", flowlogstatus]'
```

### 4. Recovery
- Rotate all credentials
- Patch vulnerabilities
- Restore from clean backup
- Update security groups

### 5. Post-Incident
- Document timeline
- Update runbooks
- Implement preventive controls
- Conduct training

## Security Scanning Schedule

- **Daily**: Container image scanning
- **Weekly**: Dependency vulnerability scanning
- **Monthly**: Penetration testing (non-prod)
- **Quarterly**: Security audit
- **Annually**: Third-party security assessment

## Compliance Reports

```bash
# Generate compliance report
aws securityhub get-findings \
  --filters '{"ComplianceStatus":[{"Value":"FAILED","Comparison":"EQUALS"}]}' \
  --output json > compliance-report.json
```
