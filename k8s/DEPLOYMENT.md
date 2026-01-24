# Continuous Deployment with ArgoCD + Helm

## Architecture

```
k8s/
├── helm/
│   └── titanic-api/
│       ├── Chart.yaml
│       ├── values.yaml           # Default values
│       ├── values-dev.yaml       # Dev overrides
│       ├── values-staging.yaml   # Staging overrides
│       ├── values-prod.yaml      # Prod overrides
│       └── templates/            # K8s templates
├── argocd/
│   └── applications/             # ArgoCD app definitions
├── deploy-app.sh                 # Manual Helm deployment
└── install-argocd.sh             # ArgoCD installation
```

## Setup

### 1. Install ArgoCD
```bash
cd k8s
./install-argocd.sh dev us-east-1
```

### 2. Update Configuration

Edit IAM role ARNs in values files:
- `helm/titanic-api/values-dev.yaml`
- `helm/titanic-api/values-staging.yaml`
- `helm/titanic-api/values-prod.yaml`


### 3. Deploy Applications
```bash
# Deploy all environments
kubectl apply -f argocd/applications/

# Or deploy individually
kubectl apply -f argocd/applications/dev.yaml
kubectl apply -f argocd/applications/staging.yaml
kubectl apply -f argocd/applications/prod.yaml
```

### 4. Sync Database Secrets
```bash

# Sync secrets for each environment
./sync-secrets.sh dev us-east-1
./sync-secrets.sh staging us-east-1
./sync-secrets.sh prod us-east-1
```

## How It Works

1. **Helm Chart**: Defines K8s resources with templating
2. **Values Files**: Environment-specific configuration
3. **ArgoCD**: Watches Git repo and auto-deploys changes

## Deployment Flow

### Dev & Staging (Auto-deploy)
```
Git Push → ArgoCD detects change → Auto-syncs → Deployed
```

### Production (Manual approval)
```
Git Push → ArgoCD detects change → Waits for approval
```

**Approve production:**
```bash
argocd app sync titanic-api-prod
```

## Test Helm Locally

```bash
cd k8s

# Preview dev config
helm template titanic-api helm/titanic-api -f helm/titanic-api/values-dev.yaml

# Preview staging config
helm template titanic-api helm/titanic-api -f helm/titanic-api/values-staging.yaml

# Preview prod config
helm template titanic-api helm/titanic-api -f helm/titanic-api/values-prod.yaml

# Install directly (without ArgoCD)
helm install titanic-api-dev helm/titanic-api -f helm/titanic-api/values-dev.yaml -n titanic-api-dev --create-namespace
```

## Manual Deployment (Without ArgoCD)

```bash
cd k8s

# Deploy to dev
./deploy-app.sh dev us-east-1

# Deploy to staging with custom image tag
./deploy-app.sh staging us-east-1 pr-5

# Deploy to prod
./deploy-app.sh prod us-east-1 v1.0.0
```

## Environment Differences

| Environment | Replicas | Resources      | Auto-Deploy |
|-------------|----------|----------------|-------------|
| Dev         | 2        | 256Mi/250m     | ✅ Yes      |
| Staging     | 3        | 256Mi/250m     | ✅ Yes      |
| Prod        | 5        | 512Mi/500m     | ❌ Manual   |

## Update Image Tag

Edit the values file:

```yaml
# helm/titanic-api/values-prod.yaml
image:
  tag: "v1.2.3"  # Change this
```

Commit and push. ArgoCD will detect and sync (or wait for approval in prod).

## Rollback

```bash
# View history
argocd app history titanic-api-prod

# Rollback to previous version
argocd app rollback titanic-api-prod

# Rollback to specific revision
argocd app rollback titanic-api-prod 5
```

## Monitor Deployments

```bash
# Watch ArgoCD apps
argocd app list

# Get app details
argocd app get titanic-api-prod

# View sync status
argocd app sync-status titanic-api-prod

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Visit: https://localhost:8080
```

## Upgrade Helm Chart

```bash
cd k8s

# Upgrade dev
helm upgrade titanic-api-dev helm/titanic-api -f helm/titanic-api/values-dev.yaml -n titanic-api-dev

# Upgrade staging
helm upgrade titanic-api-staging helm/titanic-api -f helm/titanic-api/values-staging.yaml -n titanic-api-staging

# Upgrade prod
helm upgrade titanic-api-prod helm/titanic-api -f helm/titanic-api/values-prod.yaml -n titanic-api-prod
```

## Features Implemented

✅ Rolling updates (maxUnavailable: 0, maxSurge: 1)
✅ Zero-downtime deployments
✅ Automated rollback (10 revisions kept)
✅ Multi-environment support
✅ Production approval gates
✅ GitOps workflow
✅ Helm templating for easy configuration
