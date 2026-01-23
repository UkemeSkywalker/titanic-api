# ArgoCD Continuous Deployment

## Features

- ✅ Automated deployment to Kubernetes
- ✅ Multi-environment strategy (dev/staging/prod)
- ✅ Deployment approval gates for production
- ✅ Automated rollback on failure
- ✅ Helm chart implementation

## Installation

```bash
./scripts/install-argocd.sh dev us-east-1
```

## Deploy Applications

### All Environments
```bash
kubectl apply -f argocd/applications/
```

### Individual Environments
```bash
# Dev (Auto-sync)
kubectl apply -f argocd/applications/dev.yaml

# Staging (Auto-sync)
kubectl apply -f argocd/applications/staging.yaml

# Production (Manual approval)
kubectl apply -f argocd/applications/prod.yaml
```

## Approve Production Deployment

```bash
argocd app sync titanic-api-prod
```

## Rollback

```bash
argocd app rollback titanic-api-prod
```

## Environment Configuration

- **Dev**: 2 replicas, auto-sync, 256Mi/250m
- **Staging**: 3 replicas, auto-sync, 256Mi/250m
- **Prod**: 5 replicas, manual sync, 512Mi/500m
