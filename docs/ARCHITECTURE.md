# Architecture — Much-To-Do Full Stack Deployment

## Overview

Much-To-Do runs across two Availability Zones. All compute and data resources sit in private subnets. Only the ALB and CloudFront accept internet traffic.

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

A single NAT Gateway in the public subnet gives private instances outbound internet access for package installation.

## Security Group Rules

| Security Group | Inbound | Source |
|---|---|---|
| alb-sg | 80, 443 | 0.0.0.0/0 |
| backend-sg | 8080 | alb-sg only |
| mongodb-sg | 27017 | backend-sg only |
| redis-sg | 6379 | backend-sg only |

## Data Flow

1. Browser hits the CloudFront URL. CloudFront serves the React SPA from S3.
2. React calls `VITE_API_BASE_URL` (the ALB DNS) for API requests.
3. ALB forwards each request to one of the two backend EC2 instances.
4. The backend reads and writes MongoDB in the private data subnet.
5. The backend uses ElastiCache Redis for username cache lookups.
6. The CloudWatch Agent ships all backend stdout/stderr to `/much-to-do/backend`.

## High Availability

Two backend EC2 instances run in separate AZs. The ALB health-checks `/ping` every 30 seconds. When one instance fails three checks, the ALB stops sending it traffic. AWS manages the ALB itself across both AZs.

## CI/CD Flow

```
Push to main
     │
     ├─► Infra Repo: terraform apply (infra changes only)
     │
     └─► App Repo:
          ├─► Frontend: npm build → S3 sync → CloudFront invalidation
          └─► Backend:  go build → SSM deploy to EC2 #1 → health check
                                 → SSM deploy to EC2 #2 → health check
```
