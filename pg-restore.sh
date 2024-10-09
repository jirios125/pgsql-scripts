#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Set variables
BACKUP_DIR="PATH"
ARCHIVE_DIR="ARCHIVE PATH"
POSTGRES_USER="postgres"
POSTGRES_DATA_DIR="/var/lib/pgsql/data"

# Find the latest backup
LATEST_BACKUP=$(ls -td $BACKUP_DIR/cluster_* | head -n1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "No backup found in $BACKUP_DIR"
    exit 1
fi

echo "Latest backup found: $LATEST_BACKUP"

# Stop PostgreSQL
sudo systemctl stop postgresql

# Clear the existing data directory
sudo -u $POSTGRES_USER rm -rf $POSTGRES_DATA_DIR/*

# Restore the base backup
sudo -u $POSTGRES_USER tar xzf $LATEST_BACKUP/base.tar.gz -C $POSTGRES_DATA_DIR

# Check if pg_control exists
if [ ! -f "$POSTGRES_DATA_DIR/global/pg_control" ]; then
    echo "Error: pg_control file not found. The backup may be corrupted."
    exit 1
fi

# Create recovery.signal file to initiate recovery
sudo -u $POSTGRES_USER touch $POSTGRES_DATA_DIR/recovery.signal

# Create or update postgresql.auto.conf with recovery settings
cat << EOF | sudo -u $POSTGRES_USER tee $POSTGRES_DATA_DIR/postgresql.auto.conf > /dev/null
restore_command = 'cp $ARCHIVE_DIR/%f %p'
recovery_target_timeline = 'latest'
EOF

# Set correct permissions
sudo chown -R $POSTGRES_USER:$POSTGRES_USER $POSTGRES_DATA_DIR
sudo chmod -R 700 $POSTGRES_DATA_DIR

# Start PostgreSQL
sudo systemctl start postgresql

echo "PostgreSQL is starting up. It will recover to the latest consistent state if WAL files are available."
echo "Otherwise, it will start from the state of the base backup."
echo "Check PostgreSQL logs for startup progress and any issues."

# Wait for PostgreSQL to start and then check its status
for i in {1..30}; do
    if sudo -u $POSTGRES_USER psql -c "SELECT pg_is_in_recovery();" &> /dev/null; then
        echo "PostgreSQL is up and running."
        sudo -u $POSTGRES_USER psql -c "SELECT pg_is_in_recovery();"

        # If not in recovery, remove recovery.signal
        if [ "$(sudo -u $POSTGRES_USER psql -t -c "SELECT pg_is_in_recovery();")" = " f" ]; then
            sudo -u $POSTGRES_USER rm -f $POSTGRES_DATA_DIR/recovery.signal
            echo "Recovery completed. Removed recovery.signal file."
        fi

        exit 0
    fi
    echo "Waiting for PostgreSQL to start... (attempt $i of 30)"
    sleep 10
done

echo "PostgreSQL failed to start within the expected time. Please check the logs for more information."
exit 1
