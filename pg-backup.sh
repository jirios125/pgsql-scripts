#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Set variables
BACKUP_DIR="PATH"
ARCHIVE_DIR="PATH ARCHIVE"
POSTGRES_USER="postgres"
DATE=$(date +"%Y%m%d_%H%M%S")

# Ensure backup and archive directories exist
sudo -u $POSTGRES_USER mkdir -p $BACKUP_DIR
sudo -u $POSTGRES_USER mkdir -p $ARCHIVE_DIR

# Check if WAL archiving is enabled
WAL_LEVEL=$(sudo -u $POSTGRES_USER psql -t -c "SHOW wal_level;" | tr -d '[:space:]')
ARCHIVE_MODE=$(sudo -u $POSTGRES_USER psql -t -c "SHOW archive_mode;" | tr -d '[:space:]')

if [[ $WAL_LEVEL != "replica" ]] || [[ $ARCHIVE_MODE != "on" ]]; then
    echo "WAL archiving is not properly configured. Please set up WAL archiving before running this script."
    echo "You need to modify postgresql.conf and restart PostgreSQL once to enable these settings:"
    echo "wal_level = replica"
    echo "archive_mode = on"
    echo "archive_command = 'test ! -f $ARCHIVE_DIR/%f && cp %p $ARCHIVE_DIR/%f'"
    exit 1
fi

# Perform base backup of the entire PostgreSQL cluster
BACKUP_PATH="$BACKUP_DIR/cluster_${DATE}"
sudo -u $POSTGRES_USER mkdir -p $BACKUP_PATH

echo "Starting PostgreSQL cluster backup..."
if sudo -u $POSTGRES_USER pg_basebackup -D $BACKUP_PATH -Ft -z -P -v; then
    echo "Backup of the PostgreSQL cluster completed successfully!"

    # Create a metadata file
    cat << EOF > "$BACKUP_PATH/backup_metadata.txt"
Backup Date: $(date)
PostgreSQL Version: $(sudo -u $POSTGRES_USER psql -t -c "SELECT version();" | tr -d '[:space:]')
WAL Level: $WAL_LEVEL
Archive Mode: $ARCHIVE_MODE
EOF

    echo "Metadata file created."
else
    echo "Backup of the PostgreSQL cluster failed!"
    exit 1
fi

# Optional: Clean up old backups (keeping last 7 days)
find $BACKUP_DIR -type d -mtime +7 -exec rm -rf {} +

# Optional: Clean up old WAL archives (keeping last 7 days)
find $ARCHIVE_DIR -type f -mtime +7 -exec rm -f {} +

echo "Backup process completed. Backup stored in: $BACKUP_PATH"
echo "Don't forget to periodically transfer these backups to a secure off-site location."
