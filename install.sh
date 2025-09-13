#!/bin/bash

# Installer for the Network Health Monitor toolkit

# --- Sanity Checks ---
# Must be run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

echo "=== Installing Network Health Monitor ==="

# --- File Paths ---
HEALTH_CHECK_SCRIPT="/usr/local/bin/network-health-check.sh"
SYSTEMD_SERVICE="/etc/systemd/system/network-health.service"
MOTD_SCRIPT="/etc/update-motd.d/30-network-health-motd"

# --- Create Health Check Script ---
echo "--> Creating health check script at $HEALTH_CHECK_SCRIPT..."
cat > "$HEALTH_CHECK_SCRIPT" <<'EOF'
#!/bin/bash
LOG_TAG="network-health"
PHYSICAL_INTERFACES=$(ls -l /sys/class/net | grep -v 'virtual' | awk '{print $9}')

if [ -z "$PHYSICAL_INTERFACES" ]; then
    logger -t "$LOG_TAG" "ERROR: No physical network interfaces were found."
    exit 1
fi
logger -t "$LOG_TAG" "Starting health check for interfaces: $PHYSICAL_INTERFACES"
for IFACE in $PHYSICAL_INTERFACES; do
    STATE=$(ip -o link show "$IFACE" | awk '{print $9}')
    if [ "$STATE" != "UP" ]; then
        logger -t "$LOG_TAG" "ERROR: Interface $IFACE is in a non-UP state: $STATE."
        continue
    fi
    if [[ "$IFACE" == wl* ]]; then
        logger -t "$LOG_TAG" "INFO: $IFACE is a wireless interface. Performing Wi-Fi checks..."
        if rfkill list all | grep -q -A1 "$IFACE" && rfkill list all | grep -A1 "$IFACE" | grep -q "blocked: yes"; then
            logger -t "$LOG_TAG" "WARNING: $IFACE is blocked by rfkill."
            continue
        fi
        sleep 2
        SCAN_RESULT=$(nmcli --fields SSID device wifi list ifname "$IFACE" 2>/dev/null)
        NETWORK_COUNT=$(echo "$SCAN_RESULT" | tail -n +2 | wc -l)
        if [ "$NETWORK_COUNT" -eq 0 ]; then
            logger -t "$LOG_TAG" "ERROR: $IFACE is active but found 0 Wi-Fi networks. Suspected hardware/driver failure."
        else
            logger -t "$LOG_TAG" "OK: $IFACE scanned and found $NETWORK_COUNT network(s)."
        fi
    elif [[ "$IFACE" == en* ]]; then
        logger -t "$LOG_TAG" "INFO: $IFACE is an ethernet interface. Performing ethernet checks..."
        if ip link show "$IFACE" | grep -q "NO-CARRIER"; then
            logger -t "$LOG_TAG" "ERROR: $IFACE is UP but has NO-CARRIER. Check cable and hardware."
        else
            logger -t "$LOG_TAG" "OK: $IFACE is UP and has a carrier signal."
        fi
    else
        logger -t "$LOG_TAG" "INFO: Interface $IFACE is of an unknown type, skipping specific checks."
    fi
done
logger -t "$LOG_TAG" "Health check complete."
EOF

# --- Create systemd Service File ---
echo "--> Creating systemd service at $SYSTEMD_SERVICE..."
cat > "$SYSTEMD_SERVICE" <<'EOF'
[Unit]
Description=Network Hardware Health Check
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/network-health-check.sh

[Install]
WantedBy=multi-user.target
EOF

# --- Create MOTD Alert Script ---
echo "--> Creating MOTD alert script at $MOTD_SCRIPT..."
cat > "$MOTD_SCRIPT" <<'EOF'
#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
ERROR_MSG=$(journalctl --since "24 hours ago" -t network-health | grep -i "ERROR")
if [ -n "$ERROR_MSG" ]; then
    echo
    echo -e "${RED}!! NETWORK HEALTH ALERT !!${NC}"
    echo "Potential network hardware issues were detected:"
    echo "$ERROR_MSG"
    echo
fi
EOF

# --- Set Permissions and Enable Services ---
echo "--> Setting permissions..."
chmod +x "$HEALTH_CHECK_SCRIPT"
chmod +x "$MOTD_SCRIPT"

echo "--> Enabling and starting the systemd service..."
systemctl daemon-reload
systemctl enable network-health.service
systemctl start network-health.service

echo ""
echo "=== Installation Complete! ==="
echo "The network health check will now run on every boot."
echo "Check results with: journalctl -t network-health"
