#!/bin/bash
set -e

# Change to dev environment directory 
cd "$(dirname "$0")/../environments/dev"

echo "Starting complete infrastructure deployment..."

# Check prerequisities
echo "Checking prerequisities..."

if ! command -v terraform &> /dev/null; then
echo "Terraform not found. Please install Terraform >= 1.5"
exit 1

fi

if ! command -v aws &> /dev/null; then
echo "AWS CLI not found. Please install AWS CLI v2"
exit 1

fi

if ! command -v docker &> /dev/null; then
echo "Docker not found. Please install Docker"
exit 1

fi

echo "All prerequisities met"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
echo "terraform.tfvars not found..."
exit 1

fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

if [ $? -ne 0 ]; then
echo "Terraform init failed"
exit 1

fi 

echo "Terraform initialized"

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

if [ $? -ne 0 ]; then
echo "Terraform validation failed"
exit 1

fi

echo "Configuration validated"

# Plan 
echo "Creating Terraform plan..."
terraform plan -out=tfplan

if [ $? -ne 0 ]; then
echo "Terraform plan failed"
exit 1

fi

echo "Plan created successfully"

# Confirm before applying
echo "Review the plan above. This will create AWS resources that may incur costs."
read -p "Do you want to proceed with deployment? (yes/no)" -r

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
echo "Deployment cancelled"
exit 0

fi

echo "Applying Terraform configuration..."
terraform apply tfplan

if [ $? -ne 0 ]; then
echo "Terraform  apply failed"
exit 1

fi

echo "Infrastructure deployed successfully!"

# Display outputs
echo "Deployment Summary:"
terraform output helpful_commands


echo "Deployment completed!"
