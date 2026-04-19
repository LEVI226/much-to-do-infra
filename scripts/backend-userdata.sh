#!/bin/bash
set -euo pipefail

MONGO_URI="${mongo_uri}"
DB_NAME="${db_name}"
REDIS_ADDR="${redis_addr}"
JWT_SECRET_KEY="${jwt_secret_key}"
PORT="${port}"
ALLOWED_ORIGINS="https://${allowed_origins}"

# Install dependencies
dnf install -y golang git amazon-cloudwatch-agent

# Create application user and directory
useradd -r -s /sbin/nologin muchtodo 2>/dev/null || true
mkdir -p /opt/muchtodo
chown muchtodo:muchtodo /opt/muchtodo

# Write environment file (read only by root + app user)
cat > /opt/muchtodo/.env <<ENV
PORT=$PORT
MONGO_URI=$MONGO_URI
DB_NAME=$DB_NAME
JWT_SECRET_KEY=$JWT_SECRET_KEY
JWT_EXPIRATION_HOURS=72
ENABLE_CACHE=true
REDIS_ADDR=$REDIS_ADDR
REDIS_PASSWORD=
LOG_LEVEL=info
LOG_FORMAT=json
SECURE_COOKIE=false
ALLOWED_ORIGINS=$ALLOWED_ORIGINS
COOKIE_DOMAINS=localhost
ENV
chmod 640 /opt/muchtodo/.env
chown root:muchtodo /opt/muchtodo/.env

# Clone and build the application
cd /opt/muchtodo
git clone https://github.com/LEVI226/much-to-do.git repo
cd repo/Server/MuchToDo
GOPATH=/opt/muchtodo/go go build -o /opt/muchtodo/server ./cmd/api/
chown muchtodo:muchtodo /opt/muchtodo/server

# Create systemd service
cat > /etc/systemd/system/muchtodo.service <<SERVICE
[Unit]
Description=Much-To-Do Go API Server
After=network.target

[Service]
Type=simple
User=muchtodo
WorkingDirectory=/opt/muchtodo
EnvironmentFile=/opt/muchtodo/.env
ExecStart=/opt/muchtodo/server
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=muchtodo

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable muchtodo
systemctl start muchtodo

# CloudWatch agent for log forwarding
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWCONFIG
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/muchtodo/*.log",
            "log_group_name": "/much-to-do/backend",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWCONFIG

# Also capture systemd journal output to a log file for CloudWatch
mkdir -p /var/log/muchtodo
cat > /etc/systemd/system/muchtodo-journal.service <<JOURNAL
[Unit]
Description=Pipe muchtodo journal to log file
After=muchtodo.service

[Service]
ExecStart=/usr/bin/journalctl -u muchtodo -f -o cat
StandardOutput=append:/var/log/muchtodo/app.log
Restart=always

[Install]
WantedBy=multi-user.target
JOURNAL

systemctl daemon-reload
systemctl enable muchtodo-journal
systemctl start muchtodo-journal

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
