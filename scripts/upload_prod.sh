#!/bin/bash

# Global variables
HOST="macMini"
REMOTE_DIR="/Users/jose/Projects/capili-doodba-project"
BACKUP_FILE="capili.backup.zip"
LOCAL_CONTAINER="capili-doodba-project-odoo-1"

echo "=== Uploading database from development to production ==="
echo "This will overwrite the production database!"
echo ""

# Create backup from local development database
echo "Creating backup from local development database..."
docker exec "$LOCAL_CONTAINER" click-odoo-backupdb -c auto/odoo.conf --force devel "/tmp/$BACKUP_FILE"

# Copy backup from container to local filesystem
echo "Copying backup from container to local filesystem..."
docker cp "$LOCAL_CONTAINER:/tmp/$BACKUP_FILE" "/tmp/$BACKUP_FILE"

# Remove backup file from container
docker exec "$LOCAL_CONTAINER" rm "/tmp/$BACKUP_FILE"

# Upload backup file to remote server via SCP
echo "Uploading backup to remote server..."
scp "/tmp/$BACKUP_FILE" "$HOST:/tmp/$BACKUP_FILE"

# Remove local backup file
rm "/tmp/$BACKUP_FILE"

# Ask for confirmation before restoring
echo ""
echo "⚠️  WARNING: This will OVERWRITE the production database!"
echo "Are you sure you want to restore the database in production? (yes/no)"
read -r confirmation

if [[ "$confirmation" != "yes" ]]; then
    echo "Operation cancelled."
    # Clean up remote backup file
    ssh "$HOST" "rm /tmp/$BACKUP_FILE"
    exit 1
fi

echo "Restoring database in production..."

# Execute restoration commands on remote server via SSH
ssh $HOST << 'EOF'
cd /Users/jose/Projects/capili-doodba-project
docker compose -p capili -f prod.yaml cp /tmp/capili.backup.zip odoo:/tmp/capili.backup.zip
docker compose -p capili -f prod.yaml exec odoo click-odoo-restoredb -c auto/odoo.conf --force capili /tmp/capili.backup.zip
docker compose -p capili -f prod.yaml exec --user root odoo rm /tmp/capili.backup.zip
rm /tmp/capili.backup.zip
EOF

echo "✅ Database successfully restored in production!"
