#!/bin/bash
set -e

ENVIRONMENT=$1
REGION=${2:-us-east-1}

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy-app.sh <dev|staging|prod> [region]"
  exit 1
fi

echo "🚀 Deploying Titanic API to EKS..."

# Update kubeconfig
echo "📝 Updating kubeconfig..."
aws eks update-kubeconfig --name $ENVIRONMENT-eks --region $REGION

# Get IAM role ARN
IAM_ROLE_ARN=$(terraform output -raw app_role_arn 2>/dev/null || echo "")

if [ -z "$IAM_ROLE_ARN" ]; then
  echo "⚠️  Warning: Could not get IAM role ARN from Terraform output"
  read -p "Enter IAM role ARN manually: " IAM_ROLE_ARN
fi

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace $ENVIRONMENT --dry-run=client -o yaml | kubectl apply -f -

# Sync secrets
echo "🔐 Syncing secrets..."
./scripts/sync-secrets.sh $ENVIRONMENT $REGION

# Deploy application
echo "🏗️  Deploying application..."
export ENVIRONMENT=$ENVIRONMENT
export IAM_ROLE_ARN=$IAM_ROLE_ARN
envsubst < k8s/deployment.yaml | kubectl apply -f -

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/titanic-api -n $ENVIRONMENT --timeout=5m

# Get service endpoint
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Service status:"
kubectl get svc titanic-api -n $ENVIRONMENT

echo ""
echo "🔗 Get load balancer URL:"
echo "kubectl get svc titanic-api -n $ENVIRONMENT -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
