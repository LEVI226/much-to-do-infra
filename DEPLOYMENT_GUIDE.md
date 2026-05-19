# Deployment Guide

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated
- Terraform >= 1.6
- Firebase CLI (`npm install -g firebase-tools`)
- A MongoDB Atlas cluster with a user and IP allow-list

## Why HTTPS for the backend?

The frontend is served from **Firebase Hosting** which enforces HTTPS. Browsers enforce
the **Mixed Content** policy: an HTTPS page cannot make HTTP API calls. Therefore the
backend Load Balancer must also serve HTTPS.

The backend LB uses a **static global IP** (`google_compute_global_address`) with a
**Google-managed SSL certificate** provisioned automatically via
[sslip.io](https://sslip.io) — a public wildcard DNS service where any request for
`api.<A>.<B>.<C>.<D>.sslip.io` resolves to `A.B.C.D`. This avoids the need to own a
custom domain while still enabling Google to provision a trusted TLS certificate.

After deploy the backend is reachable at:
```
https://api.<lb-ip>.sslip.io
```

> **Note:** SSL certificate provisioning takes 15–60 minutes after the first deploy.
> During that window, HTTPS requests will fail until Google completes domain validation.
> Check status with: `gcloud compute ssl-certificates describe much-to-do-ssl-cert-prod --global`

## Step 1 — Enable Required APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  redis.googleapis.com \
  secretmanager.googleapis.com \
  iap.googleapis.com \
  firebase.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  --project=project-3af03b27-5270-4519-8d1
```

## Step 2 — Bootstrap Terraform State Bucket

```bash
chmod +x scripts/bootstrap-tfstate.sh
./scripts/bootstrap-tfstate.sh project-3af03b27-5270-4519-8d1
```

## Step 3 — Configure Variables

```bash
cp prod.tfvars.example prod.tfvars
```

Edit `prod.tfvars`:
```hcl
project_id     = "project-3af03b27-5270-4519-8d1"
region         = "us-central1"
environment    = "prod"
github_repo    = "LEVI226/much-to-do"
mongo_uri      = "mongodb+srv://user:pass@cluster.mongodb.net/much_todo_db"
jwt_secret_key = "<output of: openssl rand -base64 32>"
```

## Step 4 — Deploy Infrastructure

```bash
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

## Step 5 — Post-Deploy Manual Steps

Run `terraform output post_deploy_instructions` for the full checklist, or follow below.

### 5a — Add NAT IP to MongoDB Atlas

```bash
terraform output nat_ip_address
```
Add that IP to MongoDB Atlas → Network Access → IP Allow List.

### 5b — Wait for SSL certificate

```bash
# Check provisioning status (ACTIVE = ready)
gcloud compute ssl-certificates describe much-to-do-ssl-cert-prod \
  --global \
  --format="get(managed.status,managed.domainStatus)"
```

### 5c — Set GitHub Actions Secrets

In `LEVI226/much-to-do` → Settings → Secrets and variables → Actions:

| Secret | Command |
|:---|:---|
| `WIF_PROVIDER` | `terraform output -raw wif_provider` |
| `DEPLOYER_SA_EMAIL` | `terraform output -raw github_deployer_service_account` |
| `GCP_PROJECT_ID` | `project-3af03b27-5270-4519-8d1` |
| `GCP_REGION` | `us-central1` |
| `MIG_NAME` | `terraform output -raw mig_name` |
| `VITE_API_BASE_URL` | `terraform output -raw backend_https_url` ← **HTTPS required** |
| `FIREBASE_PROJECT_ID` | `project-3af03b27-5270-4519-8d1` |

### 5d — Initialize Firebase Hosting

```bash
cd /path/to/much-to-do  # the app repo
firebase login
firebase use project-3af03b27-5270-4519-8d1
firebase deploy --only hosting
```

### 5e — Create Grader Key

```bash
gcloud iam service-accounts keys create grader-key.json \
  --iam-account=$(terraform output -raw grader_service_account) \
  --project=project-3af03b27-5270-4519-8d1
```

## Step 6 — Verify

```bash
# Backend HTTPS health check (wait for SSL cert first)
curl https://$(terraform output -raw backend_lb_domain)/health

# Backend HTTP health check (available immediately)
curl http://$(terraform output -raw backend_lb_ip)/health

# Frontend
open https://project-3af03b27-5270-4519-8d1.web.app
```

## SSH to Backend VMs (via IAP)

```bash
gcloud compute instance-groups managed list-instances \
  $(terraform output -raw mig_name) \
  --region=us-central1 \
  --project=project-3af03b27-5270-4519-8d1

gcloud compute ssh INSTANCE_NAME \
  --zone=us-central1-a \
  --tunnel-through-iap \
  --project=project-3af03b27-5270-4519-8d1
```

## Manual Rolling Deploy

```bash
chmod +x scripts/deploy-backend.sh
./scripts/deploy-backend.sh \
  project-3af03b27-5270-4519-8d1 \
  us-central1 \
  $(terraform output -raw mig_name) \
  $(terraform output -raw backend_lb_ip)
```
