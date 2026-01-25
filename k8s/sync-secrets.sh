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

# Extract values
DATABASE_URL=$(echo $SECRET_JSON | jq -r .database_url)
DB_HOST=$(echo $SECRET_JSON | jq -r .host | cut -d: -f1)
DB_USERNAME=$(echo $SECRET_JSON | jq -r .username)
DB_PASSWORD=$(echo $SECRET_JSON | jq -r .password)
DB_NAME=$(echo $SECRET_JSON | jq -r .dbname)

# Create Kubernetes secret
kubectl create secret generic db-credentials \
  --from-literal=database_url="$DATABASE_URL" \
  --from-literal=host="$DB_HOST" \
  --from-literal=username="$DB_USERNAME" \
  --from-literal=password="$DB_PASSWORD" \
  --from-literal=dbname="$DB_NAME" \
  --namespace=titanic-api-$ENVIRONMENT \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets synced successfully!"
