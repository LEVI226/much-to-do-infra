#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  One-time script: Create GCS bucket for Terraform remote state
#  Run this BEFORE `terraform init`
#  GCS backend has built-in state locking — no DynamoDB equivalent needed.
#  Usage: ./bootstrap-tfstate.sh <project-id>
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ID="${1:?Usage: $0 <project-id>}"
BUCKET="much-to-do-tfstate-gcs"
REGION="us-central1"

echo "Creating GCS bucket for Terraform state..."

gcloud storage buckets create "gs://$BUCKET" \
  --project="$PROJECT_ID" \
  --location="$REGION" \
  --uniform-bucket-level-access \
  --public-access-prevention 2>/dev/null || \
  echo "Bucket $BUCKET already exists, skipping."

gcloud storage buckets update "gs://$BUCKET" \
  --versioning \
  --project="$PROJECT_ID"

echo "State bucket ready: gs://$BUCKET"
echo ""
echo "Next steps:"
echo "  terraform init"
echo "  cp prod.tfvars.example prod.tfvars && vim prod.tfvars"
echo "  terraform apply -var-file=prod.tfvars"
