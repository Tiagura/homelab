#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Updating package list..."
sudo apt update

echo "Installing SQLite3..."
sudo apt install -y sqlite3

echo "Checking SQLite3 version..."
sqlite3 --version

#echo "Installing Rclone via script..."
#curl https://rclone.org/install.sh | sudo bash

echo "Installing Rclone from package manager..."
sudo apt install -y rclone

echo "Checking Rclone version..."
rclone --version

echo "Setup completed successfully!"
