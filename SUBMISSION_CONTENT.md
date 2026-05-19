# Much-To-Do — Cloud Infrastructure Submission (GCP)

**Role:** Cloud Engineer
**Project:** "Much-To-Do" Full Stack Application Deployment
**Cloud Provider:** Google Cloud Platform (migrated from AWS — account suspended)
**Approved by:** Amara Onyeji (Program Manager) — GCP/Azure migration approved
**Deadline:** June 7, 2026

---

## 1. Git Repositories

**Infrastructure Repo:** https://github.com/LEVI226/much-to-do-infra

Terraform code for VPC, Compute Engine (MIG), Cloud Load Balancing, Firebase Hosting, Memorystore Redis, Secret Manager, Cloud Logging, IAM + WIF, and CI/CD workflows.

**Application Fork:** https://github.com/LEVI226/much-to-do

Contains `.github/workflows/deploy-frontend.yml` and `.github/workflows/deploy-backend.yml`.

---

## 2. Architecture

```
Internet
   |
   +-- HTTPS --> Firebase Hosting (Global CDN)
   |                 +-> React SPA (https://project-3af03b27-5270-4519-8d1.web.app)
   |
   +-- HTTP --> External Global HTTP Load Balancer
                     +-> Backend Service
                           +-> Regional MIG (us-central1)
                                   +-> GCE Backend-1 (e2-small, us-central1-a, private)
                                   +-> GCE Backend-2 (e2-small, us-central1-b, private)
                                              |
                                   +----------+----------+
                              Memorystore Redis      MongoDB Atlas
                              (BASIC, private)       (external, via
                               us-central1)           static Cloud NAT)
```

**Networking:** Custom VPC · Private subnet 10.0.0.0/24 · Static NAT IP for MongoDB Atlas allow-list · Cloud Router + Cloud NAT · No external IPs on VMs · IAP-only SSH

---

## 3. Deployment Guide

Full guide: see `DEPLOYMENT_GUIDE.md` in this repo.

**Quick Start:**
```bash
./scripts/bootstrap-tfstate.sh project-3af03b27-5270-4519-8d1
terraform init
cp prod.tfvars.example prod.tfvars  # fill in values
terraform apply -var-file=prod.tfvars
terraform output post_deploy_instructions
```

After deployment, push to `main` in the app fork to trigger CI/CD pipelines.

- Frontend URL: `https://project-3af03b27-5270-4519-8d1.web.app`
- Backend API: `terraform output -raw backend_url`

---

## 4. Grader Credentials

**Service Account:** `muchtodo-dev-view@project-3af03b27-5270-4519-8d1.iam.gserviceaccount.com`
**Permissions:** `roles/viewer` + `roles/logging.viewer` + `roles/monitoring.viewer` + `roles/compute.viewer`

The grader service account is created automatically by Terraform (`modules/iam/main.tf`). After deployment, create a key:

```bash
gcloud iam service-accounts keys create grader-key.json \
  --iam-account=muchtodo-dev-view@project-3af03b27-5270-4519-8d1.iam.gserviceaccount.com \
  --project=project-3af03b27-5270-4519-8d1

gcloud auth activate-service-account --key-file=grader-key.json
```

---

## 5. Technical Compliance Matrix

| Category | Requirement | GCP Implementation | Status |
|:---|:---|:---|:---|
| **IaC** | Terraform, no manual console steps | `terraform/` directory, GCS remote state | Compliant |
| **Networking** | VPC, subnets, 2 zones, NAT | Custom VPC, private subnet, static NAT IP, Cloud Router + Cloud NAT | Compliant |
| **Firewall** | Least privilege | LB/HC CIDRs only (no 0.0.0.0/0), IAP SSH, Redis internal-only | Compliant |
| **Frontend** | CDN + HTTPS + SPA routing | Firebase Hosting (global CDN, auto-HTTPS, native SPA rewrites) | Compliant |
| **Backend** | LB + 2 instances in private, different zones | External Global HTTP LB + Regional MIG (us-central1-a/b, private) | Compliant |
| **MongoDB** | Self-hosted or managed, private access | MongoDB Atlas (external, via static Cloud NAT IP) | Compliant |
| **Redis** | Managed cache, private | Memorystore Redis 7.0 BASIC 1GB DIRECT_PEERING | Compliant |
| **CI/CD Frontend** | Build, upload, CDN invalidation | npm build + Firebase CLI deploy (CDN managed by Firebase) | Compliant |
| **CI/CD Backend** | Build, rolling deploy, health check | Go build + IAP SSH rolling deploy + LB health check | Compliant |
| **High Availability** | 2 instances across 2 zones, health checks | Regional MIG in us-central1-a/b, autohealing + LB health check | Compliant |
| **Security** | Private VMs, no secrets in Git | No external IPs, IAP-only SSH, Secret Manager, WIF (keyless) | Compliant |
| **Remote State** | Managed backend with locking | GCS backend (much-to-do-tfstate-gcs) with built-in object locking | Compliant |
| **Observability** | Logging agent on VMs, log retention | Google Cloud Ops Agent + Cloud Logging bucket (30-day retention) | Compliant |
| **Grader Access** | Read-only credentials | `muchtodo-dev-view` SA with roles/viewer (key created post-deploy) | Compliant |

---

Terraform labels all resources with `project`, `environment`, and `managed-by` tags via the provider `default_labels` block in `providers.tf`.
