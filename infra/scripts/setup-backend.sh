#!/bin/bash
set -e

# Get AWS account ID for unique bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="titanic-api-terraform-state-${ACCOUNT_ID}"
APP_NAME="titanic-api"
TABLE_NAME="terraform-state-lock-${APP_NAME}"
REGION="us-east-1"

echo "🔧 Setting up Terraform backend..."

# Create S3 bucket
echo "📦 Creating S3 bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null; then
  echo "Bucket already exists"
else
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION
  echo "Bucket created successfully"
fi

# Enable versioning
echo "🔄 Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --region $REGION \
  --versioning-configuration Status=Enabled

# Enable encryption
echo "🔒 Enabling encryption..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --region $REGION \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Block public access
echo "🚫 Blocking public access..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --region $REGION \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table
echo "🗄️  Creating DynamoDB table: $TABLE_NAME"
if aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION &>/dev/null; then
  echo "Table already exists"
else
  aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION \
    --no-cli-pager \
    --output text > /dev/null
  echo "Table created successfully"
fi

echo "✅ Backend setup complete!"
echo ""
echo "Backend configuration:"
echo "  Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $TABLE_NAME"
echo "  Region: $REGION"
echo ""
echo "📝 Generating backend.tf..."
cd "$(dirname "$0")/.."
./scripts/generate-backend.sh
