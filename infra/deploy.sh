#!/bin/bash
set -e

ENVIRONMENT=$1
ACTION=${2:-plan}
TARGET=$3
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="titanic-api-terraform-state-${ACCOUNT_ID}"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy.sh <dev|staging|prod> [plan|apply|destroy] [target]"
  echo "Example: ./deploy.sh dev apply module.eks"
  exit 1
fi

if [ ! -f "environments/$ENVIRONMENT/terraform.tfvars" ]; then
  echo "Error: Environment $ENVIRONMENT not found"
  exit 1
fi

echo "🚀 Deploying Titanic API Infrastructure"
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
if [ -n "$TARGET" ]; then
  echo "Target: $TARGET"
fi
echo ""

# Check if backend exists
if ! aws s3 ls s3://$BUCKET_NAME 2>/dev/null; then
  echo "⚠️  Backend S3 bucket not found. Creating..."
  ./scripts/setup-backend.sh
fi

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Select or create workspace
echo "🔧 Setting up workspace: $ENVIRONMENT"
terraform workspace select $ENVIRONMENT 2>/dev/null || terraform workspace new $ENVIRONMENT

# Prompt for database password
if [ "$ACTION" != "destroy" ]; then
  read -sp "Enter database password: " DB_PASSWORD
  echo ""
  
  if [ -z "$DB_PASSWORD" ]; then
    echo "Error: Database password is required"
    exit 1
  fi
fi

# Execute Terraform command
case $ACTION in
  plan)
    echo "📋 Planning infrastructure changes..."
    if [ -n "$TARGET" ]; then
      terraform plan \
        -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
        -var="db_password=$DB_PASSWORD" \
        -target="$TARGET"
    else
      terraform plan \
        -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
        -var="db_password=$DB_PASSWORD"
    fi
    ;;
  apply)
    echo "🏗️  Applying infrastructure changes..."
    if [ -n "$TARGET" ]; then
      terraform apply \
        -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
        -var="db_password=$DB_PASSWORD" \
        -target="$TARGET"
    else
      terraform apply \
        -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
        -var="db_password=$DB_PASSWORD"
    fi
    
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Configure kubectl: aws eks update-kubeconfig --name $ENVIRONMENT-eks --region us-east-1"
    echo "2. Get DB credentials: aws secretsmanager get-secret-value --secret-id $ENVIRONMENT/titanic/database"
    echo "3. Deploy application to EKS cluster"
    ;;
  destroy)
    echo "🗑️  Destroying infrastructure..."
    read -p "Are you sure you want to destroy $ENVIRONMENT? (yes/no): " CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
      if [ -n "$TARGET" ]; then
        terraform destroy \
          -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
          -var="db_password=dummy" \
          -target="$TARGET"
      else
        terraform destroy \
          -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
          -var="db_password=dummy"
      fi
      echo "✅ Infrastructure destroyed"
    else
      echo "❌ Destroy cancelled"
    fi
    ;;
  *)
    echo "Error: Invalid action. Use plan, apply, or destroy"
    exit 1
    ;;
esac
