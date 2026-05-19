# Architecture

## Overview

Much-To-Do is a full-stack task management application deployed on GCP with:
- **Frontend**: Firebase Hosting (global CDN, automatic HTTPS, SPA routing)
- **Backend**: Go API on a Regional Managed Instance Group behind a Global HTTP Load Balancer
- **Cache**: Memorystore Redis (private, DIRECT_PEERING)
- **Database**: MongoDB Atlas (external, accessed via static Cloud NAT IP)
- **Secrets**: Secret Manager with per-secret IAM bindings
- **CI/CD**: GitHub Actions with Workload Identity Federation (keyless)

## Network Topology

```
┌─────────────────────────────────────────────────────────────────────────┐
│  GCP Project: project-3af03b27-5270-4519-8d1                            │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  VPC: much-to-do-vpc-prod                                        │   │
│  │                                                                   │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │  Private Subnet: 10.0.0.0/24 (us-central1)              │    │   │
│  │  │                                                           │    │   │
│  │  │  ┌─────────────────────┐  ┌─────────────────────┐       │    │   │
│  │  │  │  GCE VM (us-c1-a)  │  │  GCE VM (us-c1-b)  │       │    │   │
│  │  │  │  e2-small, private  │  │  e2-small, private  │       │    │   │
│  │  │  │  Go API :8080       │  │  Go API :8080       │       │    │   │
│  │  │  └────────┬────────────┘  └────────┬────────────┘       │    │   │
│  │  │           │                        │                      │    │   │
│  │  │           └────────────┬───────────┘                      │    │   │
│  │  │                        │                                   │    │   │
│  │  │  ┌─────────────────────┴──────┐  ┌──────────────────┐    │    │   │
│  │  │  │  Memorystore Redis         │  │  Secret Manager  │    │    │   │
│  │  │  │  BASIC, DIRECT_PEERING     │  │  mongo-uri       │    │    │   │
│  │  │  │  :6379 (internal only)     │  │  jwt-secret      │    │    │   │
│  │  │  └────────────────────────────┘  └──────────────────┘    │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                   │   │
│  │  Cloud Router + Cloud NAT (static IP: X.X.X.X)                  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│  External Global HTTP Load Balancer (Anycast IP)                        │
│    → URL Map → Backend Service → Regional MIG                           │
└─────────────────────────────────────────────────────────────────────────┘
           │                                    │
           │                                    ▼
           │                          MongoDB Atlas (external)
           │                          (allowed: static NAT IP)
           │
    Firebase Hosting
    (global CDN, HTTPS)
    https://project-3af03b27-5270-4519-8d1.web.app
```

## IAM Design

Three service accounts, each with minimum required permissions:

```
much-to-do-backend-prod  (VM runtime)
  ├── roles/secretmanager.secretAccessor
  ├── roles/logging.logWriter
  └── roles/monitoring.metricWriter

much-to-do-deployer  (GitHub Actions — WIF, no JSON key)
  ├── roles/compute.instanceAdmin.v1
  ├── roles/iam.serviceAccountUser
  ├── roles/iap.tunnelResourceAccessor
  ├── roles/storage.objectAdmin
  └── roles/firebase.admin

muchtodo-dev-view  (grader — read-only)
  ├── roles/viewer
  ├── roles/logging.viewer
  ├── roles/monitoring.viewer
  └── roles/compute.viewer
```

## CI/CD Flow

### Frontend (Firebase Hosting)
```
push to main (Client/**) → GitHub Actions
  → google-github-actions/auth (WIF, keyless)
  → npm ci && npm run build
  → firebase deploy --only hosting
```

### Backend (Rolling MIG Deploy)
```
push to main (Server/**) → GitHub Actions
  → google-github-actions/auth (WIF, keyless)
  → go test ./...
  → For each VM in MIG:
      gcloud compute ssh --tunnel-through-iap
        → git pull + go build + systemctl restart
      wait for LB health check to pass
```

## Traffic Flow

```
User Browser
  │
  ├─── HTTPS → Firebase CDN → React SPA (index.html + /assets/*)
  │            └── SPA routing: all paths → index.html (Firebase rewrites)
  │
  └─── HTTP → External Global LB (Anycast) → Regional MIG
              └── Backend Service (port 8080, /health check)
                   ├── VM in us-central1-a
                   └── VM in us-central1-b
                        └── Go API
                             ├── Memorystore Redis (session cache)
                             └── MongoDB Atlas (via Cloud NAT static IP)
```

## Security Boundaries

| Resource | Access | Denied |
|:---|:---|:---|
| GCE VMs | LB health check CIDRs (130.211/35.191), IAP SSH (35.235) | Direct internet |
| Redis | Subnet CIDR (10.0.0.0/24) only | Anything outside subnet |
| Secret Manager | Backend SA email only | All other identities |
| VMs (SSH) | IAP tunnel (35.235.240.0/20) | Direct SSH, all other sources |
| GitHub Actions | WIF pool (LEVI226/much-to-do repo only) | All other repos/issuers |
