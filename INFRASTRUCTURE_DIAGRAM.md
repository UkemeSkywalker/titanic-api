# Titanic API - AWS Infrastructure Architecture

## ASCII Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                         │
└────────────────────────────────────┬────────────────────────────────────────────────┘
                                     │
                                     │ HTTPS/HTTP Traffic
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                  AWS CLOUD                                          │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐   │
│  │                              VPC (10.0.0.0/16)                              │   │
│  │                                                                              │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    PUBLIC SUBNETS (2 AZs)                            │   │   │
│  │  │                                                                       │   │   │
│  │  │  ┌──────────────────────────────────────────────────────────────┐   │   │   │
│  │  │  │              Application Load Balancer (ALB)                 │   │   │   │
│  │  │  │  ┌────────────┐  ┌────────────┐                             │   │   │   │
│  │  │  │  │  HTTP:80   │  │ HTTPS:443  │                             │   │   │   │
│  │  │  │  └────────────┘  └────────────┘                             │   │   │   │
│  │  │  │         │                                                     │   │   │   │
│  │  │  │         │  Security Group: ALB-SG (0.0.0.0/0 → 80,443)      │   │   │   │
│  │  │  └─────────┼─────────────────────────────────────────────────┬─┘   │   │   │
│  │  │            │                                                   │     │   │   │
│  │  │  ┌─────────┴─────────┐                         ┌─────────────┴───┐ │   │   │
│  │  │  │  Internet Gateway │                         │   NAT Gateway   │ │   │   │
│  │  │  │       (IGW)       │                         │   + Elastic IP  │ │   │   │
│  │  │  └───────────────────┘                         └─────────────────┘ │   │   │
│  │  └───────────────────────────────────────────────────────────────────┘   │   │
│  │                                │                            │              │   │
│  │                                ▼                            ▼              │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐ │   │
│  │  │                    PRIVATE SUBNETS (2 AZs)                          │ │   │
│  │  │                                                                      │ │   │
│  │  │  ┌────────────────────────────────────────────────────────────┐    │ │   │
│  │  │  │              EKS CLUSTER (Kubernetes)                      │    │ │   │
│  │  │  │                                                             │    │ │   │
│  │  │  │  ┌──────────────────────────────────────────────────────┐ │    │ │   │
│  │  │  │  │         EKS Node Group (EC2 Instances)               │ │    │ │   │
│  │  │  │  │  • Dev: 1-3 nodes (t3.small)                         │ │    │ │   │
│  │  │  │  │  • Prod: 2-5 nodes (t3.medium)                       │ │    │ │   │
│  │  │  │  │                                                       │ │    │ │   │
│  │  │  │  │  ┌─────────────────────────────────────────────┐    │ │    │ │   │
│  │  │  │  │  │         Kubernetes Pods                     │    │ │    │ │   │
│  │  │  │  │  │                                              │    │ │    │ │   │
│  │  │  │  │  │  ┌────────────────────────────────────┐    │    │ │    │ │   │
│  │  │  │  │  │  │  Titanic API Deployment            │    │    │ │    │ │   │
│  │  │  │  │  │  │  • Replicas: 2-10 (HPA)            │    │    │ │    │ │   │
│  │  │  │  │  │  │  • Image: Flask App (Python 3.11)  │    │    │ │    │ │   │
│  │  │  │  │  │  │  • Port: 5000                       │    │    │ │    │ │   │
│  │  │  │  │  │  │  • Resources: 256Mi-512Mi RAM      │    │    │ │    │ │   │
│  │  │  │  │  │  │  • CPU: 250m-500m                  │    │    │ │    │ │   │
│  │  │  │  │  │  │  • Health Checks: Liveness/Ready   │    │    │ │    │ │   │
│  │  │  │  │  │  └────────────────────────────────────┘    │    │ │    │ │   │
│  │  │  │  │  │                                              │    │ │    │ │   │
│  │  │  │  │  │  Security Group: APP-SG (ALB → 5000)        │    │ │    │ │   │
│  │  │  │  │  └──────────────────┬───────────────────────────┘    │ │    │ │   │
│  │  │  │  │                     │                                 │ │    │ │   │
│  │  │  │  └─────────────────────┼─────────────────────────────────┘ │    │ │   │
│  │  │  │                        │                                    │    │ │   │
│  │  │  │  IAM Roles:            │                                    │    │ │   │
│  │  │  │  • EKS Cluster Role    │                                    │    │ │   │
│  │  │  │  • EKS Node Role       │                                    │    │ │   │
│  │  │  │  • OIDC Provider       │                                    │    │ │   │
│  │  │  │  • Service Account     │                                    │    │ │   │
│  │  │  └────────────────────────┼────────────────────────────────────┘    │ │   │
│  │  │                           │                                          │ │   │
│  │  │                           │ Connects to                              │ │   │
│  │  │                           ▼                                          │ │   │
│  │  │  ┌────────────────────────────────────────────────────────────┐    │ │   │
│  │  │  │              RDS PostgreSQL Database                       │    │ │   │
│  │  │  │  • Engine: PostgreSQL 15.4                                 │    │ │   │
│  │  │  │  • Instance: db.t3.micro (dev) / db.t3.small (prod)        │    │ │   │
│  │  │  │  • Storage: 20GB (dev) / 100GB (prod) - GP3 Encrypted      │    │ │   │
│  │  │  │  • Multi-AZ: Enabled (prod only)                           │    │ │   │
│  │  │  │  • Backup: 7 days (dev) / 30 days (prod)                   │    │ │   │
│  │  │  │  • Performance Insights: Enabled (prod)                    │    │ │   │
│  │  │  │  • CloudWatch Logs: postgresql, upgrade                    │    │ │   │
│  │  │  │  • Port: 5432                                              │    │ │   │
│  │  │  │                                                             │    │ │   │
│  │  │  │  Security Group: RDS-SG (VPC → 5432)                       │    │ │   │
│  │  │  │  DB Subnet Group: Spans 2 AZs                              │    │ │   │
│  │  │  └────────────────────────────────────────────────────────────┘    │ │   │
│  │  │                                                                      │ │   │
│  │  └──────────────────────────────────────────────────────────────────────┘ │   │
│  │                                                                            │   │
│  └────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐   │
│  │                         AWS SECRETS MANAGER                                 │   │
│  │  • Database Credentials (auto-generated)                                    │   │
│  │  • Database URL                                                              │   │
│  │  • Environment-specific secrets                                              │   │
│  └────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐   │
│  │                         CLOUDWATCH MONITORING                               │   │
│  │  • EKS Cluster Logs (api, audit, authenticator)                             │   │
│  │  • RDS Performance Metrics                                                   │   │
│  │  • Application Logs                                                          │   │
│  └────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐   │
│  │                         TERRAFORM STATE BACKEND                             │   │
│  │  • S3 Bucket (encrypted)                                                     │   │
│  │  • DynamoDB Table (state locking)                                            │   │
│  └────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

```

## Data Flow

1. **User Request** → Internet → ALB (Port 80/443)
2. **Load Balancer** → Routes to EKS Pods (Port 5000) in private subnets
3. **Application** → Connects to RDS PostgreSQL (Port 5432)
4. **Secrets** → Retrieved from AWS Secrets Manager
5. **Monitoring** → CloudWatch collects logs and metrics
6. **Auto-scaling** → HPA scales pods based on CPU/Memory (2-10 replicas)
7. **Outbound Traffic** → NAT Gateway → Internet Gateway

## Key Features

### High Availability
- Multi-AZ deployment across 2 availability zones
- RDS Multi-AZ failover (production)
- Auto-scaling with HPA (2-10 pods)
- Load balancing with ALB

### Security
- Private subnets for compute and database
- Security groups with least privilege
- Encrypted RDS storage
- AWS Secrets Manager for credentials
- Non-root container user
- Trivy security scanning in CI/CD
- OIDC authentication for EKS

### Monitoring & Observability
- CloudWatch logs for EKS and RDS
- Performance Insights (production)
- Health checks (liveness/readiness)
- Email notifications

### Cost Optimization
- Environment-specific sizing (dev vs prod)
- NAT Gateway consolidation
- GP3 storage for better price/performance
- Auto-scaling to match demand

### Disaster Recovery
- Automated backups (7-30 days retention)
- Final snapshots before deletion (prod)
- Infrastructure as Code (Terraform)
- Multi-AZ redundancy
