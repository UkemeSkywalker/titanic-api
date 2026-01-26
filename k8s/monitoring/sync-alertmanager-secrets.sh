#!/bin/bash
set -e

ENVIRONMENT=$1
REGION=${2:-us-east-1}

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./sync-alertmanager-secrets.sh <dev|staging|prod> [region]"
  exit 1
fi

echo "🔐 Syncing AlertManager SMTP secrets from AWS Secrets Manager to Kubernetes..."

# Get secret from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$ENVIRONMENT/titanic/alertmanager-smtp" \
  --region $REGION \
  --query SecretString \
  --output text)

# Extract values
SMTP_SERVER=$(echo $SECRET_JSON | jq -r .smtp_server)
SMTP_FROM=$(echo $SECRET_JSON | jq -r .smtp_from)
SMTP_USERNAME=$(echo $SECRET_JSON | jq -r .smtp_username)
SMTP_PASSWORD=$(echo $SECRET_JSON | jq -r .smtp_password)
TEAM_EMAIL=$(echo $SECRET_JSON | jq -r .team_email)
CRITICAL_EMAIL=$(echo $SECRET_JSON | jq -r .critical_email)

# Create Kubernetes secret
kubectl create secret generic alertmanager-smtp \
  --from-literal=smtp_server="$SMTP_SERVER" \
  --from-literal=smtp_from="$SMTP_FROM" \
  --from-literal=smtp_username="$SMTP_USERNAME" \
  --from-literal=smtp_password="$SMTP_PASSWORD" \
  --from-literal=team_email="$TEAM_EMAIL" \
  --from-literal=critical_email="$CRITICAL_EMAIL" \
  --namespace=monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ AlertManager SMTP secrets synced successfully!"
echo ""
echo "📧 Configuration:"
echo "   SMTP Server: $SMTP_SERVER"
echo "   From: $SMTP_FROM"
echo "   Team Alerts: $TEAM_EMAIL"
echo "   Critical Alerts: $CRITICAL_EMAIL"
