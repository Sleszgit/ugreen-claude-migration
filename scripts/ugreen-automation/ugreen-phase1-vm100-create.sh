#!/usr/bin/env bash
################################################################################
# UGREEN Phase 1a: VM100 Creation
# Create VM100 (ugreen-infra) on UGREEN Proxmox
#
# Location: /mnt/lxc102scripts/ (LXC102)
#           /nvme2tb/lxc102scripts/ (Proxmox host)
#
# Usage: ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase1-vm100-create.sh"
#
# Note: Creates VM with Ubuntu ISO attached. Manual installation or cloud-init needed.
################################################################################

set -Eeuo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

VMID=100
VM_NAME="ugreen-infra"
VLAN_TAG=10
VM_IP="10.10.10.100"
VM_GATEWAY="10.10.10.60"
VM_CORES=4
VM_SOCKETS=1
VM_MEMORY_MB=16384  # 16GB
VM_DISK_SIZE="100G"
STORAGE_POOL="nvme2tb"
ISO_IMAGE="ubuntu-24.04-live-server-amd64.iso"
ISO_STORAGE="local"

LOG_FILE="/tmp/vm100-create-$(date +%Y%m%d-%H%M%S).log"

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

    if ! command -v qm &>/dev/null; then
        log "FATAL" "qm command not found - not running on Proxmox host"
        exit 1
    fi

    # Check if VM already exists
    if qm status $VMID &>/dev/null 2>&1; then
        log "FATAL" "VM $VMID already exists"
        exit 1
    fi

    # Check if storage pool exists
    if ! pvesh get /storage/$STORAGE_POOL &>/dev/null 2>&1; then
        log "FATAL" "Storage pool ${STORAGE_POOL} not found"
        exit 1
    fi
    log "INFO" "✓ Storage pool ${STORAGE_POOL} exists"

    # Check if ISO exists
    if ! ls /var/lib/vz/template/iso/$ISO_IMAGE &>/dev/null 2>&1; then
        log "WARN" "ISO not found at /var/lib/vz/template/iso/${ISO_IMAGE}"
        log "WARN" "You may need to download: wget https://releases.ubuntu.com/24.04/${ISO_IMAGE}"
        log "WARN" "And place it in: /var/lib/vz/template/iso/"
    else
        log "INFO" "✓ ISO found: $ISO_IMAGE"
    fi

    log "INFO" "✓ All prerequisites met"
}

create_vm100() {
    log "INFO" "Creating VM100 (${VM_NAME})..."

    # Create VM with specified configuration
    qm create $VMID \
        --name "$VM_NAME" \
        --memory $VM_MEMORY_MB \
        --cores $VM_CORES \
        --sockets $VM_SOCKETS \
        --numa 0 \
        --ostype l26 \
        --machine q35 \
        --bios ovmf \
        --efidisk0 "${STORAGE_POOL}:256,format=raw" \
        --scsi0 "${STORAGE_POOL}:${VM_DISK_SIZE},format=raw" \
        --net0 "virtio,bridge=vmbr0,tag=${VLAN_TAG}" \
        --bootdisk scsi0 \
        --boot c \
        --cdrom "local:iso/${ISO_IMAGE}" \
        --serial0 socket \
        --vga serial0 \
        --agent enabled=1 2>&1 | tee -a "$LOG_FILE"

    log "INFO" "✓ VM100 created successfully"
}

configure_vm_networking() {
    log "INFO" "Configuring static IP networking for VM100..."

    # Create cloud-init config for static IP
    cat > /tmp/user-data << 'EOF'
#cloud-config
version: 2
timezone: Europe/Warsaw
hostname: ugreen-infra
fqdn: ugreen-infra.local
manage_resolv_conf: true
resolvectl_conf:
  nameservers:
    - 192.168.40.50
    - 8.8.8.8
  search_domains:
    - local

network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 10.10.10.100/24
      gateway4: 10.10.10.60
      nameservers:
        addresses: [192.168.40.50, 8.8.8.8]

runcmd:
  - timedatectl set-timezone Europe/Warsaw
EOF

    log "INFO" "Cloud-init config created at /tmp/user-data"
    log "INFO" "Note: This will be applied during Ubuntu installation"
}

start_vm() {
    log "INFO" "Starting VM100..."

    qm start $VMID 2>&1 | tee -a "$LOG_FILE"

    # Wait for VM to start
    sleep 5

    # Check VM status
    local status=$(qm status $VMID | awk '{print $2}')
    if [[ "$status" == "running" ]]; then
        log "INFO" "✓ VM100 is running"
    else
        log "ERROR" "VM100 failed to start (status: $status)"
        exit 1
    fi
}

print_next_steps() {
    log "INFO" ""
    log "INFO" "==============================================="
    log "INFO" "✓ VM100 Created Successfully!"
    log "INFO" "==============================================="
    log "INFO" "VM Details:"
    log "INFO" "  VMID: $VMID"
    log "INFO" "  Name: $VM_NAME"
    log "INFO" "  CPU: $VM_CORES cores"
    log "INFO" "  RAM: $((VM_MEMORY_MB / 1024))GB"
    log "INFO" "  Disk: $VM_DISK_SIZE"
    log "INFO" "  IP: ${VM_IP}/24"
    log "INFO" "  Gateway: ${VM_GATEWAY}"
    log "INFO" "  VLAN Tag: $VLAN_TAG"
    log "INFO" ""
    log "INFO" "MANUAL STEPS REQUIRED:"
    log "INFO" "1. Open Proxmox console for VM100 (VMID 100)"
    log "INFO" "2. Complete Ubuntu 24.04 installation:"
    log "INFO" "   - Language: English"
    log "INFO" "   - Keyboard: Select your layout"
    log "INFO" "   - Network: DHCP first, then manually set:"
    log "INFO" "       IPv4: 10.10.10.100/24"
    log "INFO" "       Gateway: 10.10.10.60"
    log "INFO" "       DNS: 192.168.40.50"
    log "INFO" "   - Storage: Use entire disk (LVM optional)"
    log "INFO" "   - User: Create admin user (remember password!)"
    log "INFO" "   - SSH: Enable OpenSSH server"
    log "INFO" "3. After installation completes, reboot"
    log "INFO" "4. SSH to VM: ssh admin@10.10.10.100"
    log "INFO" ""
    log "INFO" "AFTER UBUNTU INSTALLATION:"
    log "INFO" "Run Phase 1b script to install Docker & Portainer:"
    log "INFO" ""
    log "INFO" "  ssh -p 22022 ugreen-host \\\"bash /nvme2tb/lxc102scripts/ugreen-phase1-vm100-docker.sh\\\""
    log "INFO" ""
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "==============================================="
    log "INFO" ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log "INFO" "==============================================="
    log "INFO" "UGREEN Phase 1a: VM100 Creation"
    log "INFO" "==============================================="
    log "INFO" "Date: $(date)"
    log "INFO" ""

    log "INFO" "[1/4] Validating prerequisites..."
    validate_prerequisites
    log "INFO" ""

    log "INFO" "[2/4] Creating VM100..."
    create_vm100
    log "INFO" ""

    log "INFO" "[3/4] Configuring networking..."
    configure_vm_networking
    log "INFO" ""

    log "INFO" "[4/4] Starting VM100..."
    start_vm
    log "INFO" ""

    print_next_steps
}

main "$@"
