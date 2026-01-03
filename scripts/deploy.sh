#!/bin/bash
# scripts/deploy.sh - Local Terraform deployment

set -e

ENVIRONMENT=${1:-demo}
AWS_REGION=${2:-us-east-1}

echo "🚀 Deploying User API with Terraform"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"

# Package Lambda function
echo "📦 Packaging Lambda function..."
zip -j lambda_deployment.zip src/get_user.py
mv lambda_deployment.zip infrastructure/

# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "📋 Planning Terraform deployment..."
terraform plan -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION"

# Apply deployment
echo "🏗️  Applying Terraform configuration..."
terraform apply -auto-approve -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION"

# Get outputs
echo "📊 Getting deployment outputs..."
API_ENDPOINT=$(terraform output -raw api_endpoint)
TABLE_NAME=$(terraform output -raw table_name)
FUNCTION_NAME=$(terraform output -raw function_name)

echo "✅ Deployment complete!"
echo "🌐 API Endpoint: $API_ENDPOINT"
echo "🗄️  Table Name: $TABLE_NAME"
echo "⚡ Function Name: $FUNCTION_NAME"

# Add sample data
echo "📝 Adding sample data..."
aws dynamodb put-item \
  --table-name $TABLE_NAME \
  --item '{"userId":{"S":"user123"},"name":{"S":"John Doe"},"email":{"S":"john@example.com"}}'

echo "🧪 Test the API:"
echo "curl $API_ENDPOINT/users/user123"

cd ..