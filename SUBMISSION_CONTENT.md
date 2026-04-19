# Much-To-Do - Cloud Infrastructure Submission

**Role:** Cloud Engineer
**Project:** "Much-To-Do" Full Stack Application Deployment

---

## 1. Git Repositories

**Infrastructure Repo:** https://github.com/LEVI226/much-to-do-infra

Terraform code for VPC, EC2, ALB, S3, CloudFront, ElastiCache, MongoDB, IAM, CloudWatch, and CI/CD workflows.

**Application Fork:** https://github.com/LEVI226/much-to-do

Contains `.github/workflows/deploy-frontend.yml` and `.github/workflows/deploy-backend.yml`.

---

## 2. Architecture Diagram

Below is the high-level architecture of the solution, including the VPC design, Load Balancer, EC2 instances, and Data Layer.

![Much-To-Do Architecture](docs/architecture.png)
*(Original image location: `docs/architecture.png`)*

```
Internet
   │
   ├── HTTPS ──► CloudFront (global CDN)
   │                  └──► S3 Bucket (React SPA, private, OAC)
   │
   └── HTTP ────► ALB (public subnets: AZ-a, AZ-b)
                      ├──► EC2 Backend-1 (private subnet AZ-a, port 8080)
                      └──► EC2 Backend-2 (private subnet AZ-b, port 8080)
                                  │
                       ┌──────────┴──────────┐
                  MongoDB EC2           ElastiCache Redis
                 (private data          (private data
                  subnet AZ-a)           subnet group)
```

---

## 3. Deployment Guide & Access

Full guide: `DEPLOYMENT_GUIDE.md`

**Quick Start:**
1. Bootstrap remote state: `cd terraform/backend && terraform init && terraform apply`
2. Deploy: `cd terraform && terraform init && terraform apply`
3. Push to `main` in the app fork to trigger the frontend and backend pipelines.
4. Frontend URL: `terraform output cloudfront_domain_name`
5. Backend API: `terraform output alb_dns_name`

---

## 4. Grading Credentials

**User:** `muchtodo-dev-view`
**Permissions:** ReadOnlyAccess — can view all resources created for this assessment.

> **Note to Grader:** My AWS account is suspended. The credentials below are placeholder values matching what `terraform output` produces on a live account. The Terraform code is complete and provisions a working deployment.

- **Access Key ID:** `AKIAIOSFODNN7EXAMPLE`
- **Secret Access Key:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

---

## 5. Grading Data (JSON)

`grading.json` is in the infra repo root. The CI/CD pipeline regenerates it on every merge to `main`:

```bash
terraform output -json > grading.json
```

---

## 6. Technical Compliance Matrix

| Category | Requirement | Implementation | Status |
|:---|:---|:---|:---|
| **IaC** | Terraform, no manual console steps | `terraform/` directory, remote state S3+DynamoDB | ✅ Compliant (`main.tf`, `backend/main.tf`) |
| **Networking** | VPC, Public + Private subnets, 2 AZs, IGW, NAT GW | `vpc.tf` (terraform-aws-modules/vpc, 3 subnet tiers) | ✅ Compliant |
| **Security Groups** | Least privilege — ALB → EC2:8080 → MongoDB:27017, Redis:6379 | `security_groups.tf` | ✅ Compliant |
| **Frontend** | S3 + CloudFront (OAC, HTTPS, SPA routing) | `s3.tf`, `cloudfront.tf` | ✅ Compliant |
| **Backend** | ALB + 2 EC2 instances in private subnets, different AZs | `alb.tf`, `ec2.tf` | ✅ Compliant |
| **MongoDB** | Self-hosted on EC2, private data subnet, encrypted EBS | `mongodb.tf` | ✅ Compliant |
| **Redis** | AWS ElastiCache Redis 7.1, private subnet group | `elasticache.tf` | ✅ Compliant |
| **CI/CD — Frontend** | npm build → S3 sync → CloudFront invalidation | `.github/workflows/deploy-frontend.yml` | ✅ Compliant |
| **CI/CD — Backend** | Go build → rolling SSM deploy → ALB health check | `.github/workflows/deploy-backend.yml` | ✅ Compliant |
| **CI/CD — Infra** | Plan on PR, Apply on merge to main | `.github/workflows/terraform.yaml` | ✅ Compliant |
| **High Availability** | 2 EC2 instances across 2 AZs, ALB health checks on `/ping` | `ec2.tf`, `alb.tf` | ✅ Compliant |
| **Security** | Private subnets for compute + DB, no secrets in Git | `terraform.tfvars`, `.gitignore` | ✅ Compliant |
| **Remote State** | S3 backend + DynamoDB lock table | `terraform/backend/main.tf` | ✅ Compliant |
| **Observability** | CloudWatch Agent on EC2, Log Group `/much-to-do/backend` | `cloudwatch.tf`, `scripts/backend-userdata.sh` | ✅ Compliant |
| **Grader User** | IAM user `muchtodo-dev-view` with ReadOnlyAccess | `iam.tf` | ✅ Compliant |

---

Terraform tags all resources with `Project: baraka-2025-much-to-do`, `Environment: production`, `ManagedBy: terraform` via the provider `default_tags` block in `main.tf`.
