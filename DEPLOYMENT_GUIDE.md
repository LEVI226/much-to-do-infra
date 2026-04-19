# Deployment Guide — Much-To-Do Infrastructure

## Prerequisites

- AWS CLI configured with credentials that have admin access
- Terraform >= 1.7
- Git

## Step 1: Bootstrap Remote State

Run this once before anything else:

```bash
cd terraform/backend
terraform init
terraform apply
```

This creates the S3 bucket and DynamoDB table used to store Terraform state.

## Step 2: Initialize and Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -var="jwt_secret_key=<your-secret>"
terraform apply -var="jwt_secret_key=<your-secret>"
```

Expected resources: VPC, subnets, NAT Gateway, ALB, 2 EC2 backend instances, MongoDB EC2, ElastiCache Redis, S3 bucket, CloudFront distribution, CloudWatch log groups, IAM user.

## Step 3: Collect Outputs

```bash
terraform output -json
```

Note the following values and add them as GitHub Actions secrets in the application fork:

| Output | Secret Name |
|---|---|
| `alb_dns_name` | `VITE_API_BASE_URL` (prefix with `http://`) + `ALB_DNS_NAME` |
| `cloudfront_domain_name` | Live frontend URL |
| `cloudfront_distribution_id` | `CLOUDFRONT_DISTRIBUTION_ID` |
| `s3_frontend_bucket` | `S3_FRONTEND_BUCKET` |
| `backend_instance_ids[0]` | `EC2_HOST_1` |
| `backend_instance_ids[1]` | `EC2_HOST_2` |

## Step 4: Deploy the Application

In your forked application repository:

1. Add all GitHub Actions secrets from Step 3
2. Push to `main` — both pipelines trigger automatically
3. Frontend pipeline deploys the React SPA to S3 and invalidates CloudFront
4. Backend pipeline builds the Go binary and rolls it out to both EC2 instances via SSM

## Step 5: Verify

```bash
# Backend health check
curl http://<alb-dns-name>/ping
# Expected: {"message":"pong"}

# Frontend
open https://<cloudfront-domain>
```

## Destroy

```bash
cd terraform
terraform destroy -var="jwt_secret_key=<your-secret>"
```

## ALB Health Check

The ALB checks `/ping` on port 8080 every 30 seconds. An instance becomes unhealthy after 3 consecutive failures. To test high availability, stop one EC2 instance from the AWS console — the ALB automatically routes all traffic to the remaining healthy instance within ~90 seconds.
