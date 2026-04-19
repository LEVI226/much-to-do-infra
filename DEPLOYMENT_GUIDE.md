# Deployment Guide — Much-To-Do Infrastructure

## Prerequisites

- AWS CLI configured with admin credentials
- Terraform >= 1.7
- Git

## Step 1: Bootstrap Remote State

Run once before deploying:

```bash
cd terraform/backend
terraform init
terraform apply
```

Creates the S3 bucket and DynamoDB lock table for Terraform state.

## Step 2: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -var="jwt_secret_key=<your-secret>"
terraform apply -var="jwt_secret_key=<your-secret>"
```

Terraform provisions: VPC, subnets, NAT Gateway, ALB, 2 EC2 backend instances, MongoDB EC2, ElastiCache Redis, S3 bucket, CloudFront distribution, CloudWatch log groups, IAM user.

## Step 3: Collect Outputs

```bash
terraform output -json
```

Copy these values into GitHub Actions secrets in the application fork:

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
2. Push to `main`. Both pipelines trigger.
3. The frontend pipeline builds the React SPA, syncs to S3, and invalidates CloudFront.
4. The backend pipeline builds the Go binary and rolls it to both EC2 instances via SSM.

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

The ALB checks `/ping` on port 8080 every 30 seconds. An instance is marked unhealthy after 3 failures. To test failover, stop one EC2 instance from the AWS console. The ALB routes all traffic to the remaining instance within 90 seconds.
