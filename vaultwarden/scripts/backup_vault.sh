#!/bin/bash

# Define paths
VAULTWARDEN_PATH="/root/vaultwarden/" # Path to the Vaultwarden main directory
VAULTWARDEN_DATA="./data"             # Path to the Vaultwarden data directory
DATE=$(date +'%Y-%m-%d_%H-%M-%S')     # Date and time in format YYYY-MM-DD_HH-MM-SS
REMOTE_NAME="remote"                  # Rclone remote name (e.g., gdrive, remote, etc.)
REMOTE_PATH="backups/vaultwarden"     # Path in Google Drive where backups will be stored
VAULTWARDEN_CONTAINER="vaultwarden"   # Name of the Docker container
ZIP_PASSWORD="your-secure-password"   # Set a secure password for the ZIP file

echo -e "--- Script executed on $(date '+%Y-%m-%d %H:%M:%S') ---"

cd "$VAULTWARDEN_PATH"

# Create a directory for the backup (name it vault-YYYY-MM-DD_HH-MM-SS)
BACKUP_FOLDER="vault-$DATE"
mkdir -p "$BACKUP_FOLDER"

# Stop the Vaultwarden Docker container
echo "Stopping Vaultwarden container..."
docker stop "$VAULTWARDEN_CONTAINER"

# Perform the SQLite databases backups if these databases exists
if [ -e "$VAULTWARDEN_DATA/db.sqlite3" ]; then
  DB_BACKUP="$BACKUP_FOLDER/db.sqlite3"
  echo "Backing up Main SQLite database..."
  sqlite3 "$VAULTWARDEN_DATA/db.sqlite3" ".backup '$DB_BACKUP'"
else
  echo "Skipping db.dqlite3: file is missing"
fi

if [ -e "$VAULTWARDEN_DATA/db.sqlite3-shm" ]; then
  cp "$VAULTWARDEN_DATA/db.sqlite3-shm" "$BACKUP_FOLDER/"
  echo "Backing up SHM database..."
else
  echo "Skipping db.sqlite3-shm: file is missing"
fi

if [ -e "$VAULTWARDEN_DATA/db.sqlite3-wal" ]; then
  cp "$VAULTWARDEN_DATA/db.sqlite3-wal" "$BACKUP_FOLDER/"
  echo "Backing up WAL database..."
else
  echo "Skipping db.sqlite3-wal: file is missing"
fi

# Copy attachments (if the directory exists)
if [ -d "$VAULTWARDEN_DATA/attachments" ]; then
  cp -r "$VAULTWARDEN_DATA/attachments" "$BACKUP_FOLDER/"
  echo "Backing up attachments folder"
else
  echo "Skipping attachments: directory is missing"
fi

# Copy the config.json file (if it exists)
if [ -f "$VAULTWARDEN_DATA/config.json" ]; then
  cp "$VAULTWARDEN_DATA/config.json" "$BACKUP_FOLDER/"
  echo "Backing up config.json"
else
  echo "Skipping config.json: file is missing"
fi

# Copy RSA key files (if they exist)
if [ -f "$VAULTWARDEN_DATA/rsa_key.der" ]; then
  cp "$VAULTWARDEN_DATA/rsa_key.der" "$BACKUP_FOLDER/"
  echo "Backing up rsa_key.der"
else
  echo "Skipping rsa_key.der: file is missing"
fi

if [ -f "$VAULTWARDEN_DATA/rsa_key.pem" ]; then
  cp "$VAULTWARDEN_DATA/rsa_key.pem" "$BACKUP_FOLDER/"
  echo "Backing up rsa_key.pem"
else
  echo "Skipping rsa_key.pem: file is missing"
fi

if [ -f "$VAULTWARDEN_DATA/rsa_key.pub.der" ]; then
  cp "$VAULTWARDEN_DATA/rsa_key.pub.der" "$BACKUP_FOLDER/"
  echo "Backing up rsa_key.pub.der"
else
  echo "Skipping rsa_key.pub.der: file is missing"
fi

# Copy the icon_cache directory (if it exists)
if [ -d "$VAULTWARDEN_DATA/icon_cache" ]; then
  cp -r "$VAULTWARDEN_DATA/icon_cache" "$BACKUP_FOLDER/"
  echo "Backing up icon_cache folder"
else
  echo "Skipping icon_cache: directory is missing"
fi

# Check if sends directory exists and copy it if present
if [ -d "$VAULTWARDEN_DATA/sends" ]; then
  cp -r "$VAULTWARDEN_DATA/sends" "$BACKUP_FOLDER/"
  echo "Backing up sends folder"
else
  echo "Skipping sends: sends directory is missing"
fi

# Zip the entire backup folder
echo "Zipping the backup folder..."
BACKUP_ZIP="$BACKUP_FOLDER.zip"
zip -r -e "$BACKUP_ZIP" "$BACKUP_FOLDER" --password "$ZIP_PASSWORD"

# Upload the backup zip file to Google Drive using Rclone
echo "Uploading the backup to Google Drive..."
rclone copy "$BACKUP_ZIP" "$REMOTE_NAME:$REMOTE_PATH"

# Optionally remove the local backup files after uploading
rm -rf "$BACKUP_FOLDER" "$BACKUP_ZIP"

# Clean up older backups on the remote (keep only the newest 3)
echo "Cleaning up older backups on the remote (keeping the newest 3)..."
rclone lsl "$REMOTE_NAME:$REMOTE_PATH" | sort -k 2 -r | tail -n +4 | while read -r line; do
  # Extract file name from the output of rclone lsl
  BACKUP_FILE=$(echo "$line" | awk '{print $NF}')
  echo "Removing old backup: $BACKUP_FILE"
  rclone delete "$REMOTE_NAME:$REMOTE_PATH/$BACKUP_FILE"
done

# Restart the Vaultwarden Docker container
echo "Restarting Vaultwarden container..."
docker start "$VAULTWARDEN_CONTAINER"

# Print success message
echo "Backup completed successfully: $BACKUP_ZIP"
