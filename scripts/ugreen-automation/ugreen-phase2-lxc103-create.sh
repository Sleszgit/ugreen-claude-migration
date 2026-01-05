#!/usr/bin/env bash
################################################################################
# UGREEN Phase 2: LXC103 Creation with GPU Passthrough
# Create LXC103 (ugreen-media) with Intel QuickSync GPU access
#
# Location: /mnt/lxc102scripts/ (LXC102)
#           /nvme2tb/lxc102scripts/ (Proxmox host)
#
# Usage: ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase2-lxc103-create.sh"
#
# Note: GPU passthrough configured for Intel QuickSync (renderD128)
################################################################################

set -Eeuo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

CTID=103
LXC_NAME="ugreen-media"
VLAN_TAG=10
LXC_IP="10.10.10.103"
LXC_GATEWAY="10.10.10.60"
LXC_CORES=4
LXC_MEMORY_MB=8192  # 8GB
LXC_SWAP_MB=512
LXC_DISK_SIZE="50G"
STORAGE_POOL="nvme2tb"
LXC_TEMPLATE="ubuntu-24.04-standard_24.04-1_amd64.tar.zst"
TEMPLATE_STORAGE="local"

# GPU configuration
GPU_DEVICE="/dev/dri/renderD128"
GPU_GID=104  # Typical GID for render group

LOG_FILE="/tmp/lxc103-create-$(date +%Y%m%d-%H%M%S).log"

# ============================================================================
# FUNCTIONS
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

error_handler() {
    local line_number=$1
    local exit_code=$2
    log "ERROR" "Script failed at line ${line_number} with exit code ${exit_code}"
    exit "${exit_code}"
}

trap 'error_handler ${LINENO} $?' ERR

validate_prerequisites() {
    log "INFO" "Validating prerequisites..."

    if [[ $EUID -ne 0 ]]; then
        log "FATAL" "This script must be run as root"
        exit 1
    fi

    if ! command -v pct &>/dev/null; then
        log "FATAL" "pct command not found - not running on Proxmox host"
        exit 1
    fi
    log "INFO" "✓ Running on Proxmox host"

    # Check if LXC already exists
    if pct status $CTID &>/dev/null 2>&1; then
        log "FATAL" "LXC $CTID already exists"
        exit 1
    fi

    # Check if storage pool exists
    if ! pvesh get /storage/$STORAGE_POOL &>/dev/null 2>&1; then
        log "FATAL" "Storage pool ${STORAGE_POOL} not found"
        exit 1
    fi
    log "INFO" "✓ Storage pool ${STORAGE_POOL} exists"

    # Check if GPU device exists on host
    if [[ ! -c "$GPU_DEVICE" ]]; then
        log "FATAL" "GPU device ${GPU_DEVICE} not found on host"
        exit 1
    fi
    log "INFO" "✓ GPU device ${GPU_DEVICE} exists"

    # Check GPU permissions
    local gpu_gid=$(stat -c "%g" "$GPU_DEVICE")
    log "INFO" "GPU device GID: ${gpu_gid}"

    # Check if LXC template exists
    if ! ls /var/lib/vz/template/cache/$LXC_TEMPLATE &>/dev/null 2>&1; then
        log "WARN" "LXC template not found: ${LXC_TEMPLATE}"
        log "WARN" "Available templates:"
        ls /var/lib/vz/template/cache/ | grep ubuntu || true
        log "WARN" "You may need to download the template from Proxmox"
    else
        log "INFO" "✓ LXC template found: $LXC_TEMPLATE"
    fi

    log "INFO" "✓ All prerequisites met"
}

create_lxc103() {
    log "INFO" "Creating LXC103 (${LXC_NAME})..."

    # Create LXC container
    pct create $CTID "${TEMPLATE_STORAGE}:vztmpl/${LXC_TEMPLATE}" \
        --hostname "$LXC_NAME" \
        --cores $LXC_CORES \
        --memory $LXC_MEMORY_MB \
        --swap $LXC_SWAP_MB \
        --storage "$STORAGE_POOL" \
        --rootfs "${STORAGE_POOL}:${LXC_DISK_SIZE}" \
        --net0 "name=eth0,bridge=vmbr0,ip=${LXC_IP}/24,gw=${LXC_GATEWAY},tag=${VLAN_TAG}" \
        --nameserver 192.168.40.50 \
        --searchdomain local \
        --ostype ubuntu \
        --features nesting=1,keyctl=1 \
        2>&1 | tee -a "$LOG_FILE"

    log "INFO" "✓ LXC103 created successfully"
}

configure_gpu_passthrough() {
    log "INFO" "Configuring GPU passthrough for LXC103..."

    local lxc_config="/etc/pve/lxc/${CTID}.conf"

    if [[ ! -f "$lxc_config" ]]; then
        log "FATAL" "LXC config file not found: ${lxc_config}"
        exit 1
    fi

    log "INFO" "Backup current config..."
    cp "$lxc_config" "${lxc_config}.backup"

    log "INFO" "Adding GPU device mapping to LXC config..."

    # Use Proxmox 8.2+ simplified syntax first
    cat >> "$lxc_config" << 'EOF'

# GPU Passthrough Configuration (Intel QuickSync)
# Proxmox 8.2+ simplified syntax:
dev0: /dev/dri/renderD128,gid=104
EOF

    log "INFO" "GPU passthrough configuration added"
    log "INFO" "Config file: ${lxc_config}"
    log "INFO" "GPU device: ${GPU_DEVICE}"
    log "INFO" "GPU GID: ${GPU_GID}"

    log "INFO" "✓ GPU passthrough configured"
}

configure_lxc_features() {
    log "INFO" "Configuring LXC features for Docker..."

    local lxc_config="/etc/pve/lxc/${CTID}.conf"

    # Ensure nesting is enabled for Docker
    grep -q "^features:" "$lxc_config" && \
        sed -i 's/^features:.*/features: nesting=1,keyctl=1/' "$lxc_config" || \
        echo "features: nesting=1,keyctl=1" >> "$lxc_config"

    log "INFO" "✓ LXC features configured for Docker"
}

start_lxc() {
    log "INFO" "Starting LXC103..."

    pct start $CTID 2>&1 | tee -a "$LOG_FILE"

    # Wait for container to start
    sleep 3

    # Check status
    local status=$(pct status $CTID 2>&1 | awk '{print $NF}')
    if [[ "$status" == "running" ]]; then
        log "INFO" "✓ LXC103 is running"
    else
        log "ERROR" "LXC103 failed to start (status: $status)"
        exit 1
    fi

    # Wait a bit more for networking
    sleep 2
}

verify_gpu_access() {
    log "INFO" "Verifying GPU device access inside LXC..."

    # Try to list DRI devices inside the container
    local dri_check=$(pct exec $CTID -- bash -c "ls -la /dev/dri/ 2>&1 | head -20" 2>&1 || true)

    if echo "$dri_check" | grep -q "renderD128"; then
        log "INFO" "✓ GPU device /dev/dri/renderD128 is accessible in LXC"
    else
        log "WARN" "GPU device may not be accessible yet"
        log "WARN" "Output from 'ls /dev/dri/':"
        log "WARN" "$dri_check"
    fi
}

verify_networking() {
    log "INFO" "Verifying networking inside LXC..."

    # Check IP configuration
    local ip_check=$(pct exec $CTID -- ip addr show eth0 2>&1 || true)
    if echo "$ip_check" | grep -q "$LXC_IP"; then
        log "INFO" "✓ IP address ${LXC_IP} configured"
    else
        log "WARN" "IP address may not be configured yet"
        log "WARN" "Current IP config:"
        log "WARN" "$ip_check"
    fi

    # Try to ping gateway
    if pct exec $CTID -- ping -c 1 -W 2 "$LXC_GATEWAY" &>/dev/null 2>&1; then
        log "INFO" "✓ Gateway ${LXC_GATEWAY} reachable"
    else
        log "WARN" "Cannot reach gateway yet (may need network restart)"
    fi
}

print_next_steps() {
    log "INFO" ""
    log "INFO" "==============================================="
    log "INFO" "✓ LXC103 Created Successfully!"
    log "INFO" "==============================================="
    log "INFO" "LXC Details:"
    log "INFO" "  CTID: $CTID"
    log "INFO" "  Name: $LXC_NAME"
    log "INFO" "  CPU Cores: $LXC_CORES"
    log "INFO" "  RAM: $((LXC_MEMORY_MB / 1024))GB"
    log "INFO" "  Disk: $LXC_DISK_SIZE"
    log "INFO" "  IP: ${LXC_IP}/24"
    log "INFO" "  Gateway: ${LXC_GATEWAY}"
    log "INFO" "  VLAN Tag: $VLAN_TAG"
    log "INFO" "  GPU: /dev/dri/renderD128 (Intel QuickSync)"
    log "INFO" ""
    log "INFO" "NEXT STEPS:"
    log "INFO" "1. Verify LXC is running: pct status $CTID"
    log "INFO" "2. SSH into LXC: ssh root@${LXC_IP}"
    log "INFO" "   (Default password is 'password', change it!)"
    log "INFO" "3. Verify GPU access: ls -la /dev/dri/"
    log "INFO" "4. Run Docker installation script:"
    log "INFO" ""
    log "INFO" "   From Proxmox host:"
    log "INFO" "   ssh -u root ${LXC_IP} 'bash -s' < /nvme2tb/lxc102scripts/ugreen-phase2-lxc103-docker.sh"
    log "INFO" ""
    log "INFO" "   Or manually in LXC:"
    log "INFO" "   pct exec $CTID -- bash /tmp/docker-install.sh"
    log "INFO" ""
    log "INFO" "Configuration file: /etc/pve/lxc/${CTID}.conf"
    log "INFO" "Backup config: /etc/pve/lxc/${CTID}.conf.backup"
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "==============================================="
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log "INFO" "==============================================="
    log "INFO" "UGREEN Phase 2: LXC103 Creation with GPU"
    log "INFO" "==============================================="
    log "INFO" "Date: $(date)"
    log "INFO" ""

    log "INFO" "[1/6] Validating prerequisites..."
    validate_prerequisites
    log "INFO" ""

    log "INFO" "[2/6] Creating LXC103..."
    create_lxc103
    log "INFO" ""

    log "INFO" "[3/6] Configuring GPU passthrough..."
    configure_gpu_passthrough
    log "INFO" ""

    log "INFO" "[4/6] Configuring LXC features..."
    configure_lxc_features
    log "INFO" ""

    log "INFO" "[5/6] Starting LXC103..."
    start_lxc
    log "INFO" ""

    log "INFO" "[6/6] Verifying setup..."
    verify_gpu_access
    verify_networking
    log "INFO" ""

    print_next_steps
}

main "$@"
