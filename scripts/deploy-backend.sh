#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Rolling Backend Deploy — MIG-aware, via IAP tunnel
#  Usage: ./deploy-backend.sh <project-id> <region> <mig-name> <lb-ip>
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT="${1:?Usage: $0 <project-id> <region> <mig-name> <lb-ip>}"
REGION="${2:?Region required}"
MIG_NAME="${3:?MIG name required}"
LB_IP="${4:?LB IP required}"

echo "=== Starting rolling deploy to MIG: $MIG_NAME ==="

# List all instances in the MIG
INSTANCES=$(gcloud compute instance-groups managed list-instances "$MIG_NAME" \
  --region="$REGION" \
  --project="$PROJECT" \
  --format="csv[no-heading](instance,zone)" 2>/dev/null)

if [ -z "$INSTANCES" ]; then
  echo "ERROR: No instances found in MIG $MIG_NAME"
  exit 1
fi

DEPLOY_CMD='
set -e
cd /opt/much-to-do/repo
git fetch origin main
git reset --hard origin/main
cd Server/MuchToDo
HOME=/root go build -o /opt/much-to-do/server ./cmd/api/
sudo chown muchtodo:muchtodo /opt/much-to-do/server
sudo systemctl restart much-to-do
sleep 5
systemctl is-active much-to-do && echo DEPLOY_OK || { echo DEPLOY_FAILED; exit 1; }
'

while IFS=',' read -r INSTANCE_URL ZONE; do
  INSTANCE=$(basename "$INSTANCE_URL")
  echo "--- Deploying to $INSTANCE ($ZONE) ---"

  gcloud compute ssh "$INSTANCE" \
    --zone="$ZONE" \
    --project="$PROJECT" \
    --tunnel-through-iap \
    --command="$DEPLOY_CMD"

  echo "--- Health check for $INSTANCE ---"
  sleep 10
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$LB_IP/health" || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    echo "Health check passed (HTTP $HTTP_CODE)"
  else
    echo "WARNING: Health check returned HTTP $HTTP_CODE — check LB logs"
  fi

  echo "--- $INSTANCE deployed successfully ---"
done <<< "$INSTANCES"

echo "=== Rolling deploy complete! ==="
