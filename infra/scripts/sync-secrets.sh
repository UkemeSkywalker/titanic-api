#!/bin/bash
set -e

ENVIRONMENT=$1
REGION=${2:-us-east-1}

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./sync-secrets.sh <dev|staging|prod> [region]"
  exit 1
fi

echo "🔐 Syncing secrets from AWS Secrets Manager to Kubernetes..."

# Get secret from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$ENVIRONMENT/titanic/database" \
  --region $REGION \
  --query SecretString \
  --output text)

# Extract database URL
DATABASE_URL=$(echo $SECRET_JSON | jq -r .database_url)

# Create Kubernetes secret
kubectl create secret generic db-credentials \
  --from-literal=database_url="$DATABASE_URL" \
  --namespace=$ENVIRONMENT \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets synced successfully!"
