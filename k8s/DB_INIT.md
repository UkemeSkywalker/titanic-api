# Database Initialization Job

Run this job **once per environment** before deploying the application.

## Prerequisites

1. RDS database exists (created by Terraform)
2. Secrets synced: `cd infra && ./scripts/sync-secrets.sh <env> us-east-1`

## Usage

```bash
# For dev
kubectl apply -f db-init-job.yaml -n titanic-api-dev

# For staging
kubectl apply -f db-init-job.yaml -n titanic-api-staging

# For prod
kubectl apply -f db-init-job.yaml -n titanic-api-prod
```

## Check Status

```bash
# Watch job
kubectl get jobs -n titanic-api-dev -w

# View logs
kubectl logs -n titanic-api-dev -l app=titanic-api-db-init

# Check if completed
kubectl get job titanic-api-db-init -n titanic-api-dev
```

## Cleanup

Job auto-deletes after 5 minutes. To delete manually:

```bash
kubectl delete job titanic-api-db-init -n titanic-api-dev
```

## What It Does

- Creates `uuid-ossp` PostgreSQL extension
- Creates `people` table with schema
- Idempotent (checks if table exists first)
- Safe to run multiple times

## Troubleshooting

If job fails, check:
```bash
kubectl describe job titanic-api-db-init -n titanic-api-dev
kubectl logs -n titanic-api-dev -l app=titanic-api-db-init
```

Common issues:
- Secret not found → Run `sync-secrets.sh`
- Connection refused → Check RDS security group
- Authentication failed → Verify password in secret
