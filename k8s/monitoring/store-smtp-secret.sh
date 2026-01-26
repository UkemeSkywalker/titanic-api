#!/bin/bash
set -e

ENVIRONMENT=$1
REGION=${2:-us-east-1}

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./store-smtp-secret.sh <dev|staging|prod> [region]"
  exit 1
fi

echo "📧 Storing SMTP credentials in AWS Secrets Manager"
echo "Environment: $ENVIRONMENT"
echo ""

# Prompt for SMTP configuration
read -p "SMTP Server (e.g., smtp.gmail.com:587): " SMTP_SERVER
read -p "From Email Address: " FROM_EMAIL
read -p "SMTP Username: " SMTP_USER
read -sp "SMTP Password/App Password: " SMTP_PASS
echo ""
read -p "Alert Recipient Email (team): " TO_EMAIL
read -p "Critical Alert Email (on-call): " CRITICAL_EMAIL

echo ""
echo "🔐 Creating secret in AWS Secrets Manager..."

# Create JSON payload
SECRET_JSON=$(cat <<EOF
{
  "smtp_server": "$SMTP_SERVER",
  "smtp_from": "$FROM_EMAIL",
  "smtp_username": "$SMTP_USER",
  "smtp_password": "$SMTP_PASS",
  "team_email": "$TO_EMAIL",
  "critical_email": "$CRITICAL_EMAIL"
}
EOF
)

# Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "$ENVIRONMENT/titanic/alertmanager-smtp" \
  --description "SMTP credentials for AlertManager" \
  --secret-string "$SECRET_JSON" \
  --region $REGION 2>/dev/null || \
aws secretsmanager update-secret \
  --secret-id "$ENVIRONMENT/titanic/alertmanager-smtp" \
  --secret-string "$SECRET_JSON" \
  --region $REGION

echo "✅ SMTP credentials stored in AWS Secrets Manager!"
echo ""
echo "Secret ID: $ENVIRONMENT/titanic/alertmanager-smtp"
echo ""
echo "Next steps:"
echo "1. Run: cd k8s/monitoring"
echo "2. Run: ./sync-alertmanager-secrets.sh $ENVIRONMENT"
echo "3. Run: ./deploy-monitoring.sh $ENVIRONMENT"
