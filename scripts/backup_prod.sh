#!/bin/bash

# Global variables
HOST="macMini"
REMOTE_DIR="/Users/jose/Projects/capili-doodba-project"
BACKUP_FILE="capili.backup.zip"
LOCAL_CONTAINER="capili-doodba-project-odoo-1"

# Execute commands on remote server via SSH
ssh $HOST << 'EOF'
cd /Users/jose/Projects/capili-doodba-project
docker compose -p capili -f prod.yaml exec --user root odoo click-odoo-backupdb -c auto/odoo.conf --force capili /opt/odoo/capili.backup.zip
docker compose -p capili -f prod.yaml cp odoo:/opt/odoo/capili.backup.zip /tmp/capili.backup.zip
docker compose -p capili -f prod.yaml exec --user root odoo rm /opt/odoo/capili.backup.zip
EOF

# Download backup file via SCP
scp "$HOST:/tmp/$BACKUP_FILE" /tmp/$BACKUP_FILE

# Remove remote backup file
ssh "$HOST" "rm /tmp/$BACKUP_FILE"

# Copy to local container
docker cp "/tmp/$BACKUP_FILE" "$LOCAL_CONTAINER:/tmp/$BACKUP_FILE"

# Restore database in local container
docker exec -it "$LOCAL_CONTAINER" click-odoo-restoredb --neutralize -c auto/odoo.conf --force devel "/tmp/$BACKUP_FILE"
