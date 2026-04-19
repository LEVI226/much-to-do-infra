# much-to-do-infra

Terraform infrastructure for the "Much-To-Do" full-stack application.
AltSchool Cloud Engineering — Baraka 2025 Third Semester Project.

## What This Provisions

| Resource | Details |
|---|---|
| VPC | 10.0.0.0/16, 3 subnet tiers, 2 AZs |
| ALB | Public-facing, routes to backend EC2s |
| EC2 (×2) | Go API server, private subnets, different AZs |
| EC2 MongoDB | Self-hosted MongoDB 7.0, private data subnet |
| ElastiCache | Redis 7.1, private data subnet |
| S3 | React SPA assets, private (OAC) |
| CloudFront | HTTPS CDN serving the S3 bucket |
| CloudWatch | Log groups for backend + MongoDB |
| IAM | EC2 instance profile, grader read-only user |

## Quick Start

```bash
# 1. Bootstrap remote state (once only)
cd terraform/backend && terraform init && terraform apply

# 2. Deploy everything
cd ../
terraform init
terraform apply -var="jwt_secret_key=<secret>"
```

See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for the full walkthrough.

## Repository Structure

```
much-to-do-infra/
├── terraform/
│   ├── backend/         # Remote state bootstrap
│   ├── main.tf          # Provider + backend config
│   ├── variables.tf     # Input variables
│   ├── terraform.tfvars # Variable values (no secrets)
│   ├── vpc.tf           # VPC, subnets, NAT Gateway
│   ├── security_groups.tf
│   ├── alb.tf           # Application Load Balancer
│   ├── ec2.tf           # Backend EC2 instances
│   ├── mongodb.tf       # MongoDB EC2
│   ├── elasticache.tf   # Redis
│   ├── s3.tf            # Frontend bucket + OAC
│   ├── cloudfront.tf    # CloudFront distribution
│   ├── cloudwatch.tf    # Log groups
│   ├── iam.tf           # IAM roles + grader user
│   └── outputs.tf
├── scripts/
│   ├── backend-userdata.sh   # EC2 bootstrap: Go app + CloudWatch agent
│   └── mongodb-userdata.sh   # EC2 bootstrap: MongoDB + CloudWatch agent
├── docs/
│   └── ARCHITECTURE.md
├── .github/workflows/
│   └── terraform.yaml        # Plan on PR, Apply on merge
├── DEPLOYMENT_GUIDE.md
├── SUBMISSION_CONTENT.md
└── grading.json
```

## Architecture

See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md).

## CI/CD

GitHub Actions runs `terraform plan` on every Pull Request and `terraform apply` on every merge to `main`. The `grading.json` artifact is uploaded after each successful apply.

Required secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `JWT_SECRET_KEY`.
