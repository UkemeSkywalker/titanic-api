# Kubernetes Deployment

This directory contains all Kubernetes and ArgoCD configurations for the Titanic API.

## Structure

```
k8s/
├── helm/                    # Helm charts
│   └── titanic-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-staging.yaml
│       ├── values-prod.yaml
│       └── templates/
├── argocd/                  # ArgoCD applications
│   ├── applications/
│   └── rollouts/
├── deploy-app.sh           # Manual deployment script
├── install-argocd.sh       # ArgoCD installation
└── DEPLOYMENT.md           # Full deployment guide

```

## Quick Start

### 1. Install ArgoCD
```bash
./install-argocd.sh dev us-east-1
```

### 2. Deploy Applications
```bash
kubectl apply -f argocd/applications/
```

### 3. Manual Deployment (Alternative)
```bash
./deploy-app.sh dev us-east-1 pr-4
```

## Documentation

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment guide.

## Image

All environments use: `ukemzyskywalker/titanic-api:pr-4`
