#!/bin/bash
set -e

# Find project root (where frontend/ and backend/ directories exist)
echo "Detecting project root..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}"))" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -d "$PROJECT_ROOT/frontend" ] || [ ! -d "$PROJECT_ROOT/backend" ]; then
    echo "Could not find frontend and backend directories"
    echo "Expected structure: project_root/{frontend,backend}"
    exit 1
fi

echo "Project root: $PROJECT_ROOT"

# Parse command line arguments or try to get from Terraform
if [ $# -eq 2 ]; then
    FRONTEND_IMAGE="$1"
    BACKEND_IMAGE="$2"
    echo "Using provided image names"
elif [ $# -eq 1 ]; then
    DOCKERHUB_USERNAME="$1"
    FRONTEND_IMAGE="$DOCKERHUB_USERNAME/3-tier-architecture:latest"
    BACKEND_IMAGE="$DOCKERHUB_USERNAME/3-tier-architecture:latest"
    echo "Using Docker Hub username: $DOCKERHUB_USERNAME"
else
    echo "Trying to get image name from Terraform outputs..."
    TERRAFORM_DIR="$PROJECT_ROOT/PROJECT-1/environments/dev"

    if [ -d "$TERRAFORM_DIR" ]; then
        cd "$TERRAFORM_DIR"
        FRONTEND_IMAGE=$(terraform output -raw frontend_docker_image 2>/dev/null || echo "")
        BACKEND_IMAGE=$(terraform output -raw backend_docker_image 2>/dev/null || echo "")
    fi

    if [ -z "$FRONTEND_IMAGE" ] || [ -z "$BACKEND_IMAGE" ]; then
        echo "Terraform outputs not available, reading from terraform.tfvars..."

        if [ -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
            FRONTEND_IMAGE=$(grep '^frontend_docker_image' "$TERRAFORM_DIR/terraform.tfvars" | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
            BACKEND_IMAGE=$(grep '^backend_docker_image' "$TERRAFORM_DIR/terraform.tfvars" | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
    fi

        # if still empty, prompt user
        if [ -z "$FRONTEND_IMAGE" ] || [ -z "$BACKEND_IMAGE" ]; then
            echo "Could not determine Docker image names"
            echo " "
            echo "Please provide your Docker Hub username or image names:"
            echo " "
            echo "Option 1: Run with username"
            echo " $0 your-dockerhub-username"
            echo " "
            echo "Option 2: Run with full image names"
            echo " $0 username/frontend:latest username/backend:latest"
            echo " "
            echo "Option 3: Set in terraform.tfvars:"
            echo "  frontend_docker_image = \"username/3-tier-architecture:latest\""
            echo "  backend_docker_image  = \"username/3-tier-architecture:latest\""
            exit 1
        fi
fi

echo "Frontend image: $FRONTEND_IMAGE"
echo "Backend image: $BACKEND_IMAGE"

# Get AWS Region
REGION="us-east-1"
if [ ! -d "$PROJECT_ROOT/PROJECT-1/environments/dev" ]; then
    cd "$PROJECT_ROOT/PROJECT-1/environments/dev" 
    REGION=$(terraform output -raw region 2>/dev/null || echo "us-east-1")
fi

# Login to Docker Hub
echo "Checking Docker Hub authentication..."
DOCKER_USERNAME=$(echo "$FRONTEND_IMAGE" | cut -d'/' -f1)
echo "Docker Hub username: $DOCKER_USERNAME"

if docker info 2>/dev/null | grep -q "Username: $DOCKER_USERNAME"; then
    echo "Already logged into Docker Hub as $DOCKER_USERNAME"
else
    echo "Not logged into Docker Hub as $DOCKER_USERNAME"
    echo "Attempting to login to Docker Hub..."

       if ! docker login; then
        echo "Docker Hub login failed"
        echo "Please run 'docker login' manually before running this script"
        exit 1
    fi
    
    echo "Successfully logged into Docker Hub"
fi

echo ""
echo "========================================"
echo "Building and Pushing FRONTEND Image"
echo "========================================"

# Build Frontend
echo "Building frontend image..."
cd "$PROJECT_ROOT/frontend"

if ! docker build -t 3-tier-architecture-frontend:latest .; then
    echo "Failed to build frontend image"
    exit 1
fi
echo "Frontend image built successfully"

# Tag frontend with multiple tags
echo "Tagging frontend image for Docker Hub..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker tag goal-tracker-frontend:latest $FRONTEND_IMAGE
docker tag goal-tracker-frontend:latest ${FRONTEND_IMAGE%:*}:$TIMESTAMP

echo "Tagged as: $FRONTEND_IMAGE"
echo "Tagged as: ${FRONTEND_IMAGE%:*}:$TIMESTAMP"

# Push frontend to Docker Hub
echo "Pushing frontend images to Docker Hub..."
if ! docker push $FRONTEND_IMAGE; then
    echo "Failed to push frontend image to Docker Hub"
    exit 1
fi

if ! docker push ${FRONTEND_IMAGE%:*}:$TIMESTAMP; then
    echo "Failed to push timestamped frontend image (non-critical)"
fi

echo "Frontend image pushed to Docker Hub successfully"

echo ""
echo "========================================"
echo "Building and Pushing BACKEND Image"
echo "========================================"

# Build backend 
echo "Building backend image..."
cd "$PROJECT_ROOT/backend"

if ! docker build -t 3-tier-architecture-backend:latest .; then
    echo "Failed to build backend image"
    exit 1
fi
echo "Backend image built successfully"

# Tag backend with multiple tags
echo "Tagging backend image for Docker Hub..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker tag 3-tier-architecture-backend:latest $BACKEND_IMAGE
docker tag 3-tier-architecture-backend:latest ${BACKEND_IMAGE%:*}:$TIMESTAMP

echo "Tagged as: $BACKEND_IMAGE"
echo "Tagged as: ${BACKEND_IMAGE%:*}:$TIMESTAMP"

# Push backend to Docker Hub
echo "Pushing backend images to Docker Hub..."
if ! docker push $BACKEND_IMAGE; then
    echo "Failed to push backend image to Docker Hub"
    exit 1
fi

if ! docker push ${BACKEND_IMAGE%:*}:$TIMESTAMP; then
    echo "Failed to push timestamped backend image (non-critical)"
fi

echo "Backend image pushed to Docker Hub successfully"

# Return to original directory
cd "$PROJECT_ROOT"

echo ""
echo "========================================"
echo "Docker Hub Push Summary"
echo "========================================"
echo "Frontend image: $FRONTEND_IMAGE"
echo "Backend image: $BACKEND_IMAGE"
echo "Images are now available on Docker Hub!"

# Extract username from image name
DOCKER_USERNAME=$(echo "$FRONTEND_IMAGE" | cut -d'/' -f1)

# Ask if user wants to trigger instance refresh (only if Terraform is deployed)
TERRAFORM_DIR="$PROJECT_ROOT/PROJECT-1/environments/dev"
if [ -d "$TERRAFORM_DIR" ]; then
    cd "$TERRAFORM_DIR"

    # Check if Terraform state exists
    if terraform state list &>/dev/null; then
        echo ""
        echo "Optional: Update running infrastructure with new images"
        read -p "Do you want to trigger ASG instance refresh to deploy new images? (y/n) " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Triggering instance refresh for frontend ASG..."
            FRONTEND_ASG=$(terraform output -raw frontend_asg_name 2>/dev/null)
            if [ -n "$FRONTEND_ASG" ]; then
                aws autoscaling start-instance-refresh \
                    --auto-scaling-group-name $FRONTEND_ASG \
                    --region $REGION 2>/dev/null && \
                echo "Frontend ASG refresh triggered: $FRONTEND_ASG" || \
                echo "Failed to trigger frontend ASG refresh (AWS CLI may not be configured)"
            else
                echo "Frontend ASG name not found in Terraform outputs"
            fi

            echo "Triggering instance refresh for backend ASG..."
            BACKEND_ASG=$(terraform output -raw backend_asg_name 2>/dev/null)
            if [ -n "$BACKEND_ASG" ]; then
                aws autoscaling start-instance-refresh \
                    --auto-scaling-group-name $BACKEND_ASG \
                    --region $REGION 2>/dev/null && \
                echo "Backend ASG refresh triggered: $BACKEND_ASG" || \
                echo "Failed to trigger backend ASG refresh (AWS CLI may not be configured)"
            else
                echo "Backend ASG name not found in Terraform outputs"
            fi

            echo ""
            echo "Instance refresh initiated. New instances will be launched with updated images."
            echo "This process may take 5-10 minutes to complete."
            echo ""
            echo "Monitor progress:"
            echo "  AWS Console: EC2 > Auto Scaling Groups > Instance Refresh tab"
            if [ -n "$FRONTEND_ASG" ]; then
                echo "  CLI: aws autoscaling describe-instance-refreshes --auto-scaling-group-name $FRONTEND_ASG --region $REGION"
            fi
        else
            echo "Skipped instance refresh. New images will be used on next scale-out or instance replacement."
        fi
    else
        echo "Terraform infrastructure not deployed yet. Skipping ASG refresh."
    fi
fi

echo ""
echo "==================================="
echo "Build and Push Complete!"
echo "==================================="
echo ""

echo "Next steps:"
echo "  1. View images on Docker Hub: https://hub.docker.com/u/$DOCKER_USERNAME"
if [ -d "$TERRAFORM_DIR" ] && terraform state list &>/dev/null 2>&1; then
    echo "  2. Access application: http://\$(cd $TERRAFORM_DIR && terraform output -raw alb_dns_name 2>/dev/null)"
    echo "  3. Check frontend logs: aws logs tail /aws/ec2/\$(cd $TERRAFORM_DIR && terraform output -raw environment 2>/dev/null)-\$(cd $TERRAFORM_DIR && terraform output -raw project 2>/dev/null)/frontend --follow --region $REGION"
    echo "  4. Check backend logs: aws logs tail /aws/ec2/\$(cd $TERRAFORM_DIR && terraform output -raw environment 2>/dev/null)-\$(cd $TERRAFORM_DIR && terraform output -raw project 2>/dev/null)/backend --follow --region $REGION"
else
    echo "  2. Deploy infrastructure: cd $PROJECT_ROOT/terraform-infra/environments/dev && terraform apply"
    echo "  3. Or test locally: cd $PROJECT_ROOT/docker-local-deployment && docker-compose up"
fi
echo ""