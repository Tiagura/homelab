#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting sysctl configuration for Tailscale..."

# Check if /etc/sysctl.d directory exists
if [ -d "/etc/sysctl.d" ]; then
  SYSCTL_CONF="/etc/sysctl.d/99-tailscale.conf"
  echo "Detected /etc/sysctl.d directory. Using $SYSCTL_CONF."
else
  SYSCTL_CONF="/etc/sysctl.conf"
  echo "/etc/sysctl.d directory not found. Using $SYSCTL_CONF."
fi

# Add sysctl configurations
echo 'Configuring sysctl settings...'
echo 'net.ipv4.ip_forward = 1' | sudo tee -a "$SYSCTL_CONF"

# Check if IPv6 is enabled
if [ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)" -eq 0 ]; then
  echo "IPv6 is enabled. Configuring IPv6 forwarding..."
  echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a "$SYSCTL_CONF"
else
  echo "IPv6 is disabled. Skipping IPv6 configuration."
fi

# Apply the sysctl settings
echo "Applying sysctl settings from $SYSCTL_CONF..."
sudo sysctl -p "$SYSCTL_CONF"

# Check if firewalld is running and apply masquerading if needed
if command -v firewall-cmd &> /dev/null && sudo firewall-cmd --state &> /dev/null; then
  echo "Detected firewalld is running. Enabling masquerading..."
  sudo firewall-cmd --permanent --add-masquerade
  sudo firewall-cmd --reload
else
  echo "firewalld is not installed or not running. Skipping masquerading configuration."
fi

echo "Sysctl configuration completed successfully!"

