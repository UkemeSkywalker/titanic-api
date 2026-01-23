#!/bin/bash
set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
APP_NAME="titanic-api"

cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "titanic-api-terraform-state-${ACCOUNT_ID}"
    key            = "terraform.tfstate"
    region         = "${REGION}"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-${APP_NAME}"
  }
}
EOF

echo "✅ backend.tf generated with bucket: titanic-api-terraform-state-${ACCOUNT_ID}"
