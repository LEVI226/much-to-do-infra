#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
#  Much-To-Do Backend — GCE Startup Script (Debian 12)
#  Template variables interpolated by Terraform templatefile()
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
exec > >(tee /var/log/startup.log | logger -t startup -s 2>/dev/console) 2>&1

echo "=== Much-To-Do backend bootstrap starting ==="

# ── System Updates and Dependencies ──────────────────────────────────────────
apt-get update -y
apt-get install -y curl git wget

# ── Install Google Cloud Ops Agent ────────────────────────────────────────────
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# ── Create app user and directories ──────────────────────────────────────────
useradd -r -s /sbin/nologin muchtodo || true
mkdir -p /opt/much-to-do /var/log/much-to-do
chown muchtodo:muchtodo /opt/much-to-do /var/log/much-to-do

# ── Clone the application repo ────────────────────────────────────────────────
cd /opt/much-to-do
if [ -d repo ]; then
  cd repo && git fetch origin main && git reset --hard origin/main && cd ..
else
  git clone --depth=1 --branch main https://github.com/LEVI226/much-to-do.git repo
fi

# ── Detect Go version from go.mod and install ─────────────────────────────────
GO_VERSION=$(grep "^go " /opt/much-to-do/repo/Server/MuchToDo/go.mod | awk '{print $2}')
echo "Installing Go $GO_VERSION (from go.mod)..."
wget -q "https://go.dev/dl/go$${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
ln -sf /usr/local/go/bin/go /usr/local/bin/go
rm /tmp/go.tar.gz
echo "Go installed: $(go version)"

# ── Fetch secrets from Secret Manager ────────────────────────────────────────
PROJECT_ID="${project_id}"
MONGO_URI=$(gcloud secrets versions access latest \
  --secret="${mongo_uri_secret_id}" --project="$PROJECT_ID")
JWT_SECRET=$(gcloud secrets versions access latest \
  --secret="${jwt_secret_id}" --project="$PROJECT_ID")

FIREBASE_URL="https://${project_id}.web.app"

# ── Write application .env file ───────────────────────────────────────────────
cat > /opt/much-to-do/.env <<EOF
PORT=${backend_port}
MONGO_URI=$MONGO_URI
DB_NAME=${db_name}
JWT_SECRET_KEY=$JWT_SECRET
JWT_EXPIRATION_HOURS=72
ENABLE_CACHE=true
REDIS_ADDR=${redis_host}
REDIS_PASSWORD=
LOG_LEVEL=INFO
LOG_FORMAT=json
SECURE_COOKIE=false
ALLOWED_ORIGINS=$FIREBASE_URL,https://${project_id}.firebaseapp.com
COOKIE_DOMAINS=web.app,firebaseapp.com
EOF
chown muchtodo:muchtodo /opt/much-to-do/.env
chmod 600 /opt/much-to-do/.env

# ── Build the application ─────────────────────────────────────────────────────
cd /opt/much-to-do/repo/Server/MuchToDo
HOME=/root go build -o /opt/much-to-do/server ./cmd/api/
chown muchtodo:muchtodo /opt/much-to-do/server
echo "Application built successfully"

# ── Configure Ops Agent for application logs ──────────────────────────────────
cat > /etc/google-cloud-ops-agent/config.yaml <<'OPSAGENT'
logging:
  receivers:
    much_to_do_app:
      type: files
      include_paths:
        - /var/log/much-to-do/app.log
  service:
    pipelines:
      default_pipeline:
        receivers: [much_to_do_app]
OPSAGENT

systemctl restart google-cloud-ops-agent

# ── Create and start systemd service ──────────────────────────────────────────
cat > /etc/systemd/system/much-to-do.service <<'UNIT'
[Unit]
Description=Much-To-Do Backend API
After=network.target

[Service]
Type=simple
User=muchtodo
WorkingDirectory=/opt/much-to-do
EnvironmentFile=/opt/much-to-do/.env
ExecStart=/opt/much-to-do/server
Restart=always
RestartSec=5
StandardOutput=append:/var/log/much-to-do/app.log
StandardError=append:/var/log/much-to-do/app.log

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable much-to-do
systemctl start much-to-do

echo "=== Bootstrap complete. Backend service started. ==="
