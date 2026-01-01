#!/bin/bash

# Script to enable Proxmox API access from LXC 102 container
# Run this on UGREEN Proxmox host as root or with sudo

set -e

FIREWALL_FILE="/etc/pve/firewall/cluster.fw"
CONTAINER_IP="192.168.40.82"
API_PORT="8006"

echo "=== Proxmox API Firewall Configuration ==="
echo "Adding rule to allow container $CONTAINER_IP to access Proxmox API on port $API_PORT"
echo ""

# Check if the rule already exists
if grep -q "Allow LXC 102 to access Proxmox API" "$FIREWALL_FILE"; then
    echo "✓ Rule already exists in firewall config"
else
    echo "Adding rule to $FIREWALL_FILE..."

    # Append the new rule to the firewall config
    # Add before any existing [RULES] section or at the end
    cat >> "$FIREWALL_FILE" << 'RULE'

# Allow LXC 102 to access Proxmox API
IN ACCEPT -source 192.168.40.82 -p tcp -dport 8006 -log nolog
RULE

    echo "✓ Rule added to firewall config"
fi

echo ""
echo "Restarting pve-firewall service..."
sudo systemctl restart pve-firewall.service

echo "✓ Firewall restarted"
echo ""
echo "=== Verification ==="
echo "Checking if rule is active:"
sudo iptables -L -n | grep 8006 || echo "(Rule filtering via iptables display)"

echo ""
echo "✓ Done! LXC 102 should now be able to access Proxmox API"
echo "  Container can now query: https://192.168.40.60:8006/api2/json/*"
