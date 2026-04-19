#!/bin/bash
set -euo pipefail

DB_NAME="${db_name}"

# Format and mount the data volume
mkfs.xfs /dev/nvme1n1 2>/dev/null || mkfs.xfs /dev/sdf 2>/dev/null || true
mkdir -p /data/db
DATA_DEV=$(lsblk -o NAME,SIZE -d -n | awk '$2~/[0-9]+G/ && $1!="nvme0n1" && $1!="xvda" {print "/dev/"$1}' | head -1)
if [ -n "$DATA_DEV" ]; then
  mount "$DATA_DEV" /data/db || true
  echo "$DATA_DEV /data/db xfs defaults 0 0" >> /etc/fstab
fi

# Install MongoDB 7.0
cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<'REPO'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
REPO

dnf install -y mongodb-org

# Configure MongoDB to listen on all interfaces (restricted by Security Group)
sed -i 's/  bindIp: 127.0.0.1/  bindIp: 0.0.0.0/' /etc/mongod.conf
sed -i "s|dbPath: /var/lib/mongo|dbPath: /data/db|" /etc/mongod.conf

chown -R mongod:mongod /data/db

systemctl enable mongod
systemctl start mongod

# Install CloudWatch agent
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWCONFIG
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/mongodb/mongod.log",
            "log_group_name": "/much-to-do/mongodb",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
