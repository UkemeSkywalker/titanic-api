#!/bin/bash
set -e

ENVIRONMENT=$1
NAMESPACE="titanic-api-$ENVIRONMENT"
REGION=${2:-us-east-1}
IMAGE_TAG=${3:-pr-4}

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy-app.sh <dev|staging|prod> [region] [image-tag]"
  exit 1
fi

echo "🚀 Deploying Titanic API to EKS with Helm..."

# Update kubeconfig
echo "📝 Updating kubeconfig..."
aws eks update-kubeconfig --name $ENVIRONMENT-eks --region $REGION

# Get IAM role ARN
cd ../infra
IAM_ROLE_ARN=$(terraform output -raw app_role_arn 2>/dev/null || echo "")
cd ../k8s

if [ -z "$IAM_ROLE_ARN" ]; then
  echo "⚠️  Warning: Could not get IAM role ARN from Terraform output"
  read -p "Enter IAM role ARN manually: " IAM_ROLE_ARN
fi

# Sync secrets
echo "🔐 Syncing secrets..."
../infra/scripts/sync-secrets.sh $ENVIRONMENT $REGION

# Deploy with Helm
echo "🏗️  Deploying application with Helm..."
helm upgrade --install titanic-api-$ENVIRONMENT \
  ./helm/titanic-api \
  -f ./helm/titanic-api/values-$ENVIRONMENT.yaml \
  --set image.tag=$IMAGE_TAG \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$IAM_ROLE_ARN \
  --namespace $NAMESPACE \
  --create-namespace \
  --wait \
  --timeout 5m

# Get service endpoint
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Service status:"
kubectl get svc -n $NAMESPACE

echo ""
echo "🔗 Get load balancer URL:"
kubectl get svc -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
echo ""
