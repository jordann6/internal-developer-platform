#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"
PROJECT="idp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Step 1: Terraform Init and Apply ==="
cd "$REPO_ROOT/terraform/environments/dev"
terraform init
terraform apply -auto-approve

ECR_URL=$(terraform output -raw ecr_repository_url)
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)
BACKSTAGE_URL=$(terraform output -raw backstage_url)

echo ""
echo "=== Step 2: Build and Push Backstage Image ==="
cd "$REPO_ROOT/backstage"

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

IMAGE_TAG="v$(date +%Y%m%d%H%M%S)"
docker build -t "$ECR_URL:$IMAGE_TAG" .
docker push "$ECR_URL:$IMAGE_TAG"

echo ""
echo "=== Step 3: Update ECS Service ==="
aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --force-new-deployment \
  --region "$REGION" \
  --no-cli-pager

echo ""
echo "=== Deployment Complete ==="
echo "Backstage URL: $BACKSTAGE_URL"
echo "Image: $ECR_URL:$IMAGE_TAG"
echo ""
echo "Wait 2 to 3 minutes for the service to stabilize, then open the URL."
