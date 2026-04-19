# Architecture — Much-To-Do Full Stack Deployment

## Overview

The Much-To-Do application is deployed on AWS across two Availability Zones for high availability. All compute and data resources run in private subnets. Only the ALB and CloudFront are internet-facing.

```
Internet
   │
   ├──── HTTPS ──────► CloudFront (global CDN)
   │                        │
   │                        └──── S3 (React SPA, private, OAC)
   │
   └──── HTTP ───────► Application Load Balancer (public subnets: AZ-a, AZ-b)
                            │
                            ├─── Port 8080 ─► EC2 Backend-1 (private subnet AZ-a)
                            │                       │
                            └─── Port 8080 ─► EC2 Backend-2 (private subnet AZ-b)
                                                    │
                                         ┌──────────┴──────────┐
                                         │                     │
                                  MongoDB EC2            ElastiCache Redis
                                  (private data          (private data
                                   subnet AZ-a)           subnet group)
```

## VPC Design

| Component | CIDR | Purpose |
|---|---|---|
| VPC | 10.0.0.0/16 | Entire network |
| Public Subnet AZ-a | 10.0.1.0/24 | ALB node |
| Public Subnet AZ-b | 10.0.2.0/24 | ALB node |
| Private App Subnet AZ-a | 10.0.11.0/24 | Backend EC2 #1 |
| Private App Subnet AZ-b | 10.0.12.0/24 | Backend EC2 #2 |
| Private Data Subnet AZ-a | 10.0.21.0/24 | MongoDB EC2 |
| Private Data Subnet AZ-b | 10.0.22.0/24 | ElastiCache |

A single NAT Gateway in the public subnet allows private instances to reach the internet for package installation and outbound calls.

## Security Group Rules (Least Privilege)

| Security Group | Inbound | Source |
|---|---|---|
| alb-sg | 80, 443 | 0.0.0.0/0 |
| backend-sg | 8080 | alb-sg only |
| mongodb-sg | 27017 | backend-sg only |
| redis-sg | 6379 | backend-sg only |

## Data Flow

1. User opens the CloudFront URL → CloudFront serves the React SPA from S3
2. React app calls `VITE_API_BASE_URL` (the ALB DNS) for API requests
3. ALB forwards requests to one of the two backend EC2 instances (round-robin)
4. Backend reads/writes MongoDB in the private data subnet
5. Backend uses ElastiCache Redis for username cache lookups
6. All backend stdout/stderr is forwarded to CloudWatch Logs via the CloudWatch Agent

## High Availability

- Two backend EC2 instances in separate AZs
- ALB performs health checks on `/ping` every 30 seconds
- If one instance fails its health check, ALB routes all traffic to the healthy instance
- The ALB itself is managed (multi-AZ by design)

## CI/CD Data Flow

```
Push to main
     │
     ├─► Infra Repo: terraform apply (infra changes only)
     │
     └─► App Repo:
          ├─► Frontend Pipeline: npm build → S3 sync → CloudFront invalidation
          └─► Backend Pipeline: go build → SSM deploy to EC2 #1 → health check
                                       → SSM deploy to EC2 #2 → health check
```
