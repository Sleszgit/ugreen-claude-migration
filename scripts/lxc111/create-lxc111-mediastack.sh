#!/usr/bin/env bash
set -Eeuo pipefail

# LXC111 MediaStack Container Creation Script
# Purpose: Create unprivileged Debian 12 container with storage mounts, GPU passthrough, and dynamic networking
# Author: Claude Code
# Date: 2026-01-18

trap 'echo "ERROR on line $LINENO, exit code $?"' ERR

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') | $*"
}

# ============================================================================
# CONFIGURATION
# ============================================================================

LXC_ID=111
HOSTNAME="MediaStack"
CORES=4
MEMORY=8192
SWAP=1024
STORAGE_SIZE=32

# Network - Options: "dhcp" for dynamic IP, or static IP (e.g., "192.168.40.111/24")
NETWORK_MODE="dhcp"
# If using static IP, set gateway:
# NETWORK_MODE="192.168.40.111/24"
# NETWORK_GATEWAY="192.168.40.1"

# Bridge (standard Ugreen network)
BRIDGE="vmbr0"

# ============================================================================
# VALIDATION
# ============================================================================

log "Validating prerequisites..."

# Check if running on Proxmox host
if ! command -v pct &> /dev/null; then
  echo "FATAL: 'pct' command not found. This script must run on Proxmox host."
  exit 1
fi

# Check if template exists
if ! sudo pct list | grep -q "^$LXC_ID"; then
  log "✓ LXC ID $LXC_ID is available"
else
  echo "FATAL: LXC ID $LXC_ID already exists."
  exit 1
fi

# Find latest Debian 12 template dynamically
TEMPLATE_PATH=$(ls -1 /var/lib/vz/template/cache/debian-12-standard_*_amd64.tar.zst 2>/dev/null | sort -V | tail -1)
if [ -z "$TEMPLATE_PATH" ]; then
  echo "FATAL: No Debian 12 template found in /var/lib/vz/template/cache/"
  exit 1
fi
log "✓ Template found: $TEMPLATE_PATH"

# Convert path to Proxmox template reference
TEMPLATE_FILENAME=$(basename "$TEMPLATE_PATH")
TEMPLATE="local:vztmpl/$TEMPLATE_FILENAME"

# Check storage pool exists
if ! sudo pvesh get /storage/local-lvm &> /dev/null; then
  echo "FATAL: Storage pool 'local-lvm' not found."
  exit 1
fi
log "✓ Storage pool 'local-lvm' exists"

# Check mount points exist
for mount_point in "/SeriesUgreen" "/storage/Media/Series918/TVshows918" "/nvme2tb/lxc102scripts"; do
  if [ ! -d "$mount_point" ]; then
    echo "WARNING: Mount point $mount_point does not exist on host"
  else
    log "✓ Mount point $mount_point exists"
  fi
done

# Find render group GID dynamically
RENDER_GID=$(getent group render | cut -d: -f3)
if [ -z "$RENDER_GID" ]; then
  echo "FATAL: 'render' group not found on host"
  exit 1
fi
log "✓ Render group GID: $RENDER_GID"

# Verify users group exists
USERS_GID=$(getent group users | cut -d: -f3)
if [ -z "$USERS_GID" ]; then
  echo "FATAL: 'users' group not found on host"
  exit 1
fi
log "✓ Users group GID: $USERS_GID"

# ============================================================================
# FIX SUBORDINATE GID DELEGATIONS (/etc/subgid)
# ============================================================================

log ""
log "Fixing subordinate GID delegations for unprivileged container..."

SUBGID_FILE="/etc/subgid"

# Check and add users group delegation (root:$USERS_GID:1)
if ! sudo grep -q "^root:$USERS_GID:1$" "$SUBGID_FILE"; then
  log "Adding users group delegation to $SUBGID_FILE (root:$USERS_GID:1)"
  echo "root:$USERS_GID:1" | sudo tee -a "$SUBGID_FILE" > /dev/null
else
  log "✓ Users group delegation already exists in $SUBGID_FILE"
fi

# Check and add render group delegation (root:$RENDER_GID:1)
if ! sudo grep -q "^root:$RENDER_GID:1$" "$SUBGID_FILE"; then
  log "Adding render group delegation to $SUBGID_FILE (root:$RENDER_GID:1)"
  echo "root:$RENDER_GID:1" | sudo tee -a "$SUBGID_FILE" > /dev/null
else
  log "✓ Render group delegation already exists in $SUBGID_FILE"
fi

log ""
log "Current /etc/subgid (relevant lines):"
sudo grep "^root:" "$SUBGID_FILE" | grep -E "$USERS_GID|$RENDER_GID"

# ============================================================================
# CREATE CONTAINER
# ============================================================================

log ""
log "Creating LXC container $LXC_ID..."

# Build network configuration
if [ "$NETWORK_MODE" = "dhcp" ]; then
  NET0_CONFIG="name=eth0,bridge=$BRIDGE,ip=dhcp,type=veth"
  log "Using DHCP for network configuration"
else
  NET0_CONFIG="name=eth0,bridge=$BRIDGE,ip=$NETWORK_MODE,type=veth"
  log "Using static IP: $NETWORK_MODE"
fi

sudo pct create $LXC_ID $TEMPLATE \
  --hostname $HOSTNAME \
  --cores $CORES \
  --memory $MEMORY \
  --swap $SWAP \
  --rootfs local-lvm:$STORAGE_SIZE \
  --net0 "$NET0_CONFIG" \
  --features nesting=1,keyctl=1 \
  --unprivileged 1 \
  --ostype debian \
  --start 0

log "✓ Container created with ID $LXC_ID"

# ============================================================================
# CONFIGURE CONTAINER (Bind Mounts, ID Mapping, GPU)
# ============================================================================

log ""
log "Configuring container..."

CONFIG_FILE="/etc/pve/lxc/$LXC_ID.conf"

# Add bind mounts
log "Adding bind mounts..."
sudo tee -a "$CONFIG_FILE" > /dev/null <<'MOUNTS'

# --- BIND MOUNTS ---
# Main Ugreen Storage
mp0: /SeriesUgreen,mp=/mnt/media/tv_ugreen
# Old Synology Data
mp1: /storage/Media/Series918/TVshows918,mp=/mnt/media/tv_918
# LXC102 Scripts (cross-machine access)
mp2: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts
MOUNTS

log "✓ Bind mounts configured"

# Add ID mapping for users group (GID 100) and render group (dynamic GID)
log "Adding ID mapping for unprivileged container (users GID=$USERS_GID, render GID=$RENDER_GID)..."

# Build ID mapping string dynamically to handle both users and render groups
cat << IDMAP | sudo tee -a "$CONFIG_FILE" > /dev/null

# --- ID MAPPING (Access for users group GID $USERS_GID and render group GID $RENDER_GID) ---
lxc.idmap: u 0 100000 65536
lxc.idmap: g 0 100000 $USERS_GID
lxc.idmap: g $USERS_GID $USERS_GID 1
lxc.idmap: g $((USERS_GID + 1)) $((100000 + USERS_GID + 1)) $((RENDER_GID - USERS_GID - 1))
lxc.idmap: g $RENDER_GID $RENDER_GID 1
lxc.idmap: g $((RENDER_GID + 1)) $((100000 + RENDER_GID + 1)) $((65536 - RENDER_GID - 1))
IDMAP

log "✓ ID mapping configured"

# Add GPU passthrough (Intel QuickSync)
log "Adding GPU passthrough (Intel QuickSync)..."
sudo tee -a "$CONFIG_FILE" > /dev/null <<'GPU'

# --- GPU PASSTHROUGH (Intel QuickSync - /dev/dri/renderD128) ---
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file 0, 0
GPU

log "✓ GPU passthrough configured"

# ============================================================================
# VERIFY CONFIGURATION
# ============================================================================

log ""
log "Configuration file contents (last 30 lines):"
sudo tail -30 "$CONFIG_FILE"

# ============================================================================
# START CONTAINER
# ============================================================================

log ""
log "Starting container $LXC_ID..."
sudo pct start $LXC_ID

log "✓ Container started"

# Wait for network
log "Waiting for network interface to come up..."
sleep 5

# ============================================================================
# VERIFY STARTUP
# ============================================================================

log ""
log "Verifying network configuration..."
sudo pct exec $LXC_ID -- ip addr show eth0

log ""
log "Verifying bind mounts..."
sudo pct exec $LXC_ID -- mount | grep -E "tv_ugreen|tv_918|lxc102scripts" || log "WARNING: Some mounts not yet visible"

log ""
log "Verifying network connectivity..."
sudo pct exec $LXC_ID -- ping -c 1 8.8.8.8 || log "WARNING: Network ping failed (may need more boot time or check gateway)"

# ============================================================================
# COMPLETION
# ============================================================================

log ""
log "=========================================="
log "✓ LXC111 MediaStack creation complete!"
log "=========================================="
log ""
log "Container Details:"
log "  VMID: $LXC_ID"
log "  Hostname: $HOSTNAME"
log "  Network Mode: $NETWORK_MODE"
log "  Bridge: $BRIDGE"
log "  Storage: $STORAGE_SIZE GB (local-lvm)"
log "  Cores: $CORES"
log "  Memory: $MEMORY MB"
log ""
log "ID Mapping:"
log "  Users group (GID $USERS_GID) → mapped 1:1 to container"
log "  Render group (GID $RENDER_GID) → mapped 1:1 to container"
log ""
log "Bind Mounts:"
log "  /SeriesUgreen → /mnt/media/tv_ugreen"
log "  /storage/Media/Series918/TVshows918 → /mnt/media/tv_918"
log "  /nvme2tb/lxc102scripts → /mnt/lxc102scripts"
log ""
log "GPU Passthrough: Enabled (Intel QuickSync /dev/dri/renderD128)"
log ""
log "Next Steps:"
log "1. Get the assigned IP address:"
log "   sudo pct exec $LXC_ID -- ip addr show eth0"
log "2. Set up SSH access from LXC102 (replace <LXC111_IP> with actual IP):"
log "   ssh-keyscan -H <LXC111_IP> >> ~/.ssh/known_hosts"
log "   ssh-copy-id -i ~/.ssh/id_rsa.pub root@<LXC111_IP>"
log "3. Verify all mounts are accessible:"
log "   ssh root@<LXC111_IP> 'mount | grep -E tv_ugreen|tv_918|lxc102scripts'"
log ""
