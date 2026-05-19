# GCP Requirements Compliance Matrix

| Category | Requirement | GCP Implementation | Terraform Resource | Status |
|:---|:---|:---|:---|:---|
| **IaC** | Terraform, no manual console steps | All resources in `terraform/` | `providers.tf`, all modules | Compliant |
| **Remote State** | Managed backend with locking | GCS backend (built-in object locking) | `backend.tf` | Compliant |
| **Networking** | VPC, subnets, 2 zones, NAT | Custom VPC, private subnet 10.0.0.0/24, Cloud Router + Cloud NAT | `modules/vpc` | Compliant |
| **Static NAT IP** | Deterministic outbound IP for MongoDB Atlas | `google_compute_address` (EXTERNAL) + `MANUAL_ONLY` NAT | `modules/vpc/main.tf` | Compliant |
| **Firewall** | Least privilege | LB/HC CIDRs only (no 0.0.0.0/0), IAP SSH, Redis internal | `modules/firewall` | Compliant |
| **Frontend** | CDN + HTTPS + SPA routing | Firebase Hosting (global CDN, auto-HTTPS, SPA rewrites) | Manual + CI/CD | Compliant |
| **Backend** | LB + 2 instances in private, 2 zones | External Global HTTP LB + Regional MIG (us-central1-a/b, private) | `modules/compute`, `modules/load_balancer` | Compliant |
| **High Availability** | 2 instances across 2 zones, health checks | MIG with distribution_policy_zones, autohealing + LB health check | `modules/compute` | Compliant |
| **MongoDB** | Self-hosted or managed, private access | MongoDB Atlas (external, via static Cloud NAT IP) | Allow-list post-deploy | Compliant |
| **Redis** | Managed cache, private | Memorystore Redis 7.0 BASIC 1GB DIRECT_PEERING | `modules/memorystore` | Compliant |
| **Secrets** | Secrets not in Git, centrally managed | Secret Manager with per-secret IAM | `modules/secrets` | Compliant |
| **IAM** | Least-privilege service accounts | 3 SAs: backend runtime, GitHub deployer, grader (read-only) | `modules/iam` | Compliant |
| **CI/CD Frontend** | Build, upload, CDN invalidation | npm build + Firebase CLI deploy (CDN cache handled by Firebase) | `.github/workflows/deploy-frontend.yml` | Compliant |
| **CI/CD Backend** | Build, rolling deploy, health check | Go build via IAP SSH + rolling MIG deploy + LB health check | `.github/workflows/deploy-backend.yml` | Compliant |
| **Keyless CI/CD** | No long-lived credentials | Workload Identity Federation (WIF) — GitHub OIDC → GCP | `modules/iam` | Compliant |
| **Security** | Private VMs, no secrets in Git | No external IPs, IAP-only SSH, Secret Manager, no SA keys output | All modules | Compliant |
| **Observability** | Logging agent on VMs, log retention | Google Cloud Ops Agent + Cloud Logging bucket (30-day retention) | `modules/logging`, `scripts/startup.sh` | Compliant |
| **Resource Labels** | All resources tagged | `default_labels` in provider: project, environment, managed-by | `providers.tf` | Compliant |
| **Grader Access** | Read-only credentials | `muchtodo-dev-view` SA with roles/viewer (key created post-deploy) | `modules/iam` | Compliant |

## AWS → GCP Service Mapping

| AWS Service | GCP Equivalent | Notes |
|:---|:---|:---|
| VPC + Subnets | Cloud VPC + Subnetworks | GCP uses global VPC, regional subnets |
| NAT Gateway | Cloud NAT + Cloud Router | GCP NAT is regional, uses static IP |
| Application Load Balancer | External Global HTTP Load Balancer | GCP is global Anycast by default |
| EC2 Auto Scaling Group | Regional Managed Instance Group (MIG) | Template-based, rolling updates built-in |
| CloudFront + S3 | Firebase Hosting | Auto-HTTPS, global CDN, SPA routing native |
| ElastiCache Redis | Memorystore Redis | Managed, private, DIRECT_PEERING |
| SSM Parameter Store | Secret Manager | Per-secret IAM instead of project-level |
| IAM Roles | IAM Service Accounts + Roles | Three SAs instead of one |
| GitHub OIDC with AWS | Workload Identity Federation | Keyless, no JSON keys in GitHub secrets |
| SSM Session Manager | IAP SSH Tunnel | No bastion host or SSH keys needed |
| CloudWatch | Cloud Logging + Cloud Monitoring | Ops Agent replaces CloudWatch agent |
| S3 (state) + DynamoDB (lock) | GCS (state + built-in locking) | GCS has object versioning = atomic locking |
