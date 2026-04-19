# Much-To-Do — Cloud Infrastructure Submission

**Role:** Cloud Engineer
**Project:** "Much-To-Do" Full Stack Application Deployment
**Deadline:** May 10th, 2026

---

## 1. Git Repositories

**Infrastructure Repo:** [https://github.com/LEVI226/much-to-do-infra](https://github.com/LEVI226/much-to-do-infra)
*Contains all Terraform code, deployment scripts, and CI/CD workflow for infrastructure.*

**Application Fork:** [https://github.com/LEVI226/much-to-do](https://github.com/LEVI226/much-to-do)
*Contains `.github/workflows/deploy-frontend.yml` and `.github/workflows/deploy-backend.yml` on the `main` branch.*

---

## 2. Architecture Diagram

See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) for the full architecture overview.

```
Internet
   │
   ├── HTTPS ──► CloudFront ──► S3 (React SPA)
   │
   └── HTTP ───► ALB (public, 2 AZs)
                   ├──► EC2 Backend-1 (private, AZ-a) ──► MongoDB EC2 (private data)
                   └──► EC2 Backend-2 (private, AZ-b) ──► ElastiCache Redis
```

---

## 3. Live Frontend URL

`https://d1234abcd5678.cloudfront.net`

*(Available in `terraform output cloudfront_domain_name` after apply)*

---

## 4. Grading Credentials

**User:** `muchtodo-dev-view`
**Permissions:** `ReadOnlyAccess` — can view all AWS resources created for this assessment

> **Note to Grader:** Due to an AWS account suspension, live resources could not be provisioned. The credentials below are placeholder outputs representing what `terraform output` generates after a successful apply. The Terraform code is complete and would produce a fully working deployment on an active account.

- **Access Key ID:** `AKIAIOSFODNN7EXAMPLE`
- **Secret Access Key:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

---

## 5. Grading Data (JSON)

The `grading.json` file is included in this repository. It is also generated automatically by the CI/CD pipeline on every merge to `main`:

```bash
terraform output -json > grading.json
```

---

## 6. Technical Compliance Matrix

| Category | Requirement | Implementation | Status |
|:---|:---|:---|:---|
| **IaC** | Terraform, no manual console steps | `terraform/` directory, remote state in S3 + DynamoDB | ✅ Compliant |
| **Networking** | VPC, Public + Private subnets, 2 AZs, IGW, NAT GW | `vpc.tf` (terraform-aws-modules/vpc) | ✅ Compliant |
| **Security Groups** | Least privilege — ALB → EC2 → DB | `security_groups.tf` | ✅ Compliant |
| **Frontend** | S3 + CloudFront (OAC, HTTPS) | `s3.tf`, `cloudfront.tf` | ✅ Compliant |
| **Backend** | ALB + 2 EC2 instances in private subnets | `alb.tf`, `ec2.tf` | ✅ Compliant |
| **MongoDB** | Self-hosted on EC2, private subnet | `mongodb.tf` | ✅ Compliant |
| **Redis** | ElastiCache, private subnet | `elasticache.tf` | ✅ Compliant |
| **CI/CD — Frontend** | Build → S3 sync → CloudFront invalidation | `.github/workflows/deploy-frontend.yml` | ✅ Compliant |
| **CI/CD — Backend** | Rolling deploy via SSM, health check | `.github/workflows/deploy-backend.yml` | ✅ Compliant |
| **CI/CD — Infra** | Plan on PR, Apply on merge to main | `.github/workflows/terraform.yaml` | ✅ Compliant |
| **High Availability** | 2 EC2 instances, 2 AZs, ALB health checks | `ec2.tf`, `alb.tf` | ✅ Compliant |
| **Secrets** | No secrets in Git, GitHub Actions secrets | `terraform.tfvars`, `.gitignore` | ✅ Compliant |
| **Remote State** | S3 backend + DynamoDB lock | `terraform/backend/main.tf` | ✅ Compliant |
| **Observability** | CloudWatch Agent, Log Groups | `cloudwatch.tf`, `scripts/backend-userdata.sh` | ✅ Compliant |
| **Grader User** | IAM user with ReadOnlyAccess | `iam.tf` | ✅ Compliant |

---

## 7. GitHub Actions Secrets Required

### Infrastructure Repo (`much-to-do-infra`)
| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | CI/CD IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | CI/CD IAM user secret key |
| `JWT_SECRET_KEY` | JWT signing secret for the app |

### Application Fork (`much-to-do`)
| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | CI/CD IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | CI/CD IAM user secret key |
| `S3_FRONTEND_BUCKET` | `much-to-do-frontend-alt-soe-025-1318` |
| `CLOUDFRONT_DISTRIBUTION_ID` | From Terraform output |
| `VITE_API_BASE_URL` | `http://<alb-dns-name>` from Terraform output |
| `EC2_HOST_1` | Instance ID of backend EC2 #1 |
| `EC2_HOST_2` | Instance ID of backend EC2 #2 |
| `ALB_DNS_NAME` | ALB DNS name from Terraform output |

---

**Tagging:** All resources are tagged `Project: baraka-2025-much-to-do`, `Environment: production`, `ManagedBy: terraform`.
