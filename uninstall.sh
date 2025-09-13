#!/bin/bash

# Uninstaller for the Network Health Monitor toolkit

# --- Sanity Checks ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

echo "=== Uninstalling Network Health Monitor ==="

# --- File Paths ---
HEALTH_CHECK_SCRIPT="/usr/local/bin/network-health-check.sh"
SYSTEMD_SERVICE="/etc/systemd/system/network-health.service"
MOTD_SCRIPT="/etc/update-motd.d/30-network-health-motd"

# --- Disable and Stop Service ---
echo "--> Disabling and stopping systemd service..."
systemctl stop network-health.service
systemctl disable network-health.service

# --- Remove Files ---
echo "--> Removing files..."
rm -f "$HEALTH_CHECK_SCRIPT"
rm -f "$SYSTEMD_SERVICE"
rm -f "$MOTD_SCRIPT"

# --- Final Cleanup ---
echo "--> Reloading systemd..."
systemctl daemon-reload

echo ""
echo "=== Uninstallation Complete! ==="

