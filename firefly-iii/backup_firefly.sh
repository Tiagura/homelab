#!/bin/bash

# Define variables
WORK_DIR="/root/firefly-iii/"
BACKUP_SCRIPT="./firefly-iii-backuper.sh" # Path to the original backup script
DATE=$(date +'%Y-%m-%d_%H-%M-%S')     # Date and time in format YYYY-MM-DD_HH-MM-SS
BACKUP_FILE="./firefly-$DATE.tar.gz" # Backup file with timestamp
RCLONE_REMOTE="remote:/backups/firefly" # Rclone destination path
MAX_BACKUPS=3 # Maximum number of backups to keep on Google Drive

echo -e "--- Script executed on $DATE ---"

cd "$WORK_DIR"

# Run the firefly-iii-backuper.sh script
if [ -x "$BACKUP_SCRIPT" ]; then
    echo "Running the Firefly III backup script..."
    source $BACKUP_SCRIPT backup $BACKUP_FILE
    if [ $? -ne 0 ]; then
        echo "Error: Backup script failed to execute successfully."
        exit 1
    fi
else
    echo "Error: Backup script not found or not executable at $BACKUP_SCRIPT."
    exit 1
fi

# Check if the backup file was created
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not created: $BACKUP_FILE."
    exit 1
fi

# Upload the backup file to Google Drive using rclone
echo "Uploading backup file to $RCLONE_REMOTE..."
rclone copy "$BACKUP_FILE" "$RCLONE_REMOTE" --verbose
if [ $? -ne 0 ]; then
    echo "Error: Failed to upload backup file to $RCLONE_REMOTE."
    exit 1
fi

# Remove old backups, keeping only the last $MAX_BACKUPS
echo "Removing old backups, keeping only the last $MAX_BACKUPS..."
OLD_BACKUPS=$(rclone ls "$RCLONE_REMOTE" | sort -k2 | head -n -$MAX_BACKUPS | awk '{print $2}')
for BACKUP in $OLD_BACKUPS; do
    echo "Deleting old backup: $BACKUP"
    rclone delete "$RCLONE_REMOTE/$BACKUP"
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to delete old backup: $BACKUP"
    fi
done

echo "Removing .tar.gz local file"
rm -rf "$BACKUP_FILE"

echo "Backup and upload process completed successfully."
exit 0
