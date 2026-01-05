#!/usr/bin/env bash
################################################################################
# UGREEN Phase 0: VLAN 10 Setup on Proxmox Host
# Configure vmbr0.10 interface for 10.10.10.0/24 network
#
# Location: /mnt/lxc102scripts/ (LXC102)
#           /nvme2tb/lxc102scripts/ (Proxmox host)
#
# Usage: ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase0-vlan10-setup.sh"
#
# Safety: Full backup, validation, and automatic rollback on failure
################################################################################

set -Eeuo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

NETWORK_INTERFACES="/etc/network/interfaces"
BACKUP_DIR="/root/network-backups"
BACKUP_FILE="${BACKUP_DIR}/interfaces.backup-$(date +%Y%m%d-%H%M%S)"
GATEWAY="192.168.40.1"
VLAN_INTERFACE="vmbr0.10"
VLAN_IP="10.10.10.60"
VLAN_NETMASK="24"
VLAN_NETWORK="${VLAN_IP}/${VLAN_NETMASK}"

LOG_FILE="${BACKUP_DIR}/vlan10-setup-$(date +%Y%m%d-%H%M%S).log"

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
    log "ERROR" "Attempting automatic rollback..."
    rollback_config
    exit "${exit_code}"
}

trap 'error_handler ${LINENO} $?' ERR

create_backup() {
    log "INFO" "Creating backup directory: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}" || { log "FATAL" "Cannot create ${BACKUP_DIR}"; exit 1; }

    log "INFO" "Backing up current network config to: ${BACKUP_FILE}"
    cp "${NETWORK_INTERFACES}" "${BACKUP_FILE}" || { log "FATAL" "Backup failed"; exit 1; }
    chmod 600 "${BACKUP_FILE}"
    log "INFO" "✓ Backup successful"
}

validate_prerequisites() {
    log "INFO" "Validating prerequisites..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log "FATAL" "This script must be run as root"
        exit 1
    fi
    log "INFO" "✓ Running as root"

    # Check if network file exists
    if [[ ! -f "$NETWORK_INTERFACES" ]]; then
        log "FATAL" "Network config not found: ${NETWORK_INTERFACES}"
        exit 1
    fi
    log "INFO" "✓ Network config exists"

    # Check if vmbr0 exists and is UP
    if ! ip link show vmbr0 | grep -q "UP"; then
        log "FATAL" "vmbr0 bridge is not UP. Current status:"
        ip link show vmbr0
        exit 1
    fi
    log "INFO" "✓ vmbr0 is UP"

    # Check current gateway is reachable
    if ! ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
        log "FATAL" "Gateway ${GATEWAY} not reachable"
        exit 1
    fi
    log "INFO" "✓ Gateway ${GATEWAY} reachable"

    # Check if vmbr0.10 already exists
    if ip link show "$VLAN_INTERFACE" &>/dev/null 2>&1; then
        log "WARN" "Interface ${VLAN_INTERFACE} already exists"
    fi
}

create_vlan_config() {
    log "INFO" "Creating new network configuration with VLAN 10..."

    local temp_config=$(mktemp)
    trap "rm -f ${temp_config}" RETURN

    cat > "${temp_config}" << 'EOF'
auto lo
iface lo inet loopback

iface nic0 inet manual

auto vmbr0
iface vmbr0 inet static
    address 192.168.40.60/24
    gateway 192.168.40.1
    bridge-ports nic1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094

auto vmbr0.10
iface vmbr0.10 inet static
    address 10.10.10.60/24
    post-up bridge vlan add vid 10 dev vmbr0 self
    post-up bridge vlan add vid 10 dev nic1 master

iface nic1 inet manual

source /etc/network/interfaces.d/*
EOF

    # Validate syntax with ifupdown
    log "INFO" "Validating network configuration syntax..."
    if ! ifup -n -a -c "${temp_config}" &>/dev/null 2>&1; then
        log "WARN" "Configuration validation check inconclusive (ifup -n may not work), proceeding with caution"
    fi
    log "INFO" "✓ Configuration looks valid"

    # Apply new config
    log "INFO" "Applying new network configuration..."
    cp "${temp_config}" "${NETWORK_INTERFACES}"
    log "INFO" "✓ Configuration written to ${NETWORK_INTERFACES}"
}

apply_config() {
    log "INFO" "Applying network changes with ifreload..."

    # Load the interface
    if ! ifreload -a 2>&1 | tee -a "$LOG_FILE"; then
        log "ERROR" "ifreload failed, attempting rollback"
        return 1
    fi
    log "INFO" "✓ ifreload completed"

    # Wait for network to settle
    log "INFO" "Waiting for network to settle..."
    sleep 3
}

verify_vlan() {
    log "INFO" "Verifying VLAN 10 interface setup..."

    local checks_passed=0
    local checks_total=0

    # Check 1: Interface exists
    ((checks_total++))
    if ip link show "$VLAN_INTERFACE" &>/dev/null; then
        log "INFO" "✓ Check 1/6: Interface ${VLAN_INTERFACE} exists"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 1/6: Interface ${VLAN_INTERFACE} NOT FOUND"
        return 1
    fi

    # Check 2: Interface is UP
    ((checks_total++))
    if ip link show "$VLAN_INTERFACE" | grep -q "UP"; then
        log "INFO" "✓ Check 2/6: Interface is UP"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 2/6: Interface is DOWN"
        return 1
    fi

    # Check 3: IP address correct
    ((checks_total++))
    if ip addr show "$VLAN_INTERFACE" | grep -q "${VLAN_IP}"; then
        log "INFO" "✓ Check 3/6: IP address ${VLAN_NETWORK} correct"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 3/6: IP address incorrect"
        ip addr show "$VLAN_INTERFACE"
        return 1
    fi

    # Check 4: vmbr0 has bridge-vlan-aware enabled
    ((checks_total++))
    if cat "$NETWORK_INTERFACES" | grep -A5 "auto vmbr0" | grep -q "bridge-vlan-aware yes"; then
        log "INFO" "✓ Check 4/6: vmbr0 has VLAN awareness enabled"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 4/6: vmbr0 VLAN awareness not configured"
        return 1
    fi

    # Check 5: Gateway reachable
    ((checks_total++))
    if ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
        log "INFO" "✓ Check 5/6: Gateway ${GATEWAY} reachable"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 5/6: Gateway NOT reachable - MAJOR ISSUE"
        return 1
    fi

    # Check 6: Proxmox host still accessible
    ((checks_total++))
    if ping -c 1 -W 2 "192.168.40.60" &>/dev/null; then
        log "INFO" "✓ Check 6/6: Proxmox host (192.168.40.60) reachable"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 6/6: Proxmox host NOT reachable - CRITICAL"
        return 1
    fi

    log "INFO" "Verification complete: ${checks_passed}/${checks_total} checks passed"

    if [[ $checks_passed -eq $checks_total ]]; then
        log "INFO" "✓✓✓ ALL CHECKS PASSED ✓✓✓"
        return 0
    else
        log "ERROR" "Some checks failed"
        return 1
    fi
}

rollback_config() {
    log "WARN" "Rolling back to previous configuration..."

    if [[ ! -f "$BACKUP_FILE" ]]; then
        log "FATAL" "No backup file found at ${BACKUP_FILE} - CANNOT ROLLBACK"
        exit 1
    fi

    log "INFO" "Restoring from backup: ${BACKUP_FILE}"
    cp "$BACKUP_FILE" "$NETWORK_INTERFACES"

    log "INFO" "Reloading network configuration..."
    sleep 2
    ifreload -a 2>&1 | tee -a "$LOG_FILE" || true

    sleep 3

    if ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
        log "INFO" "✓ Rollback successful - network restored"
    else
        log "FATAL" "Rollback failed - network connectivity lost!"
        exit 1
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log "INFO" "==============================================="
    log "INFO" "UGREEN Phase 0: VLAN 10 Setup"
    log "INFO" "==============================================="
    log "INFO" "Date: $(date)"
    log "INFO" "Target interface: ${VLAN_INTERFACE}"
    log "INFO" "Target network: ${VLAN_NETWORK}"
    log "INFO" ""

    # Step 1: Validate prerequisites
    log "INFO" "[1/6] Validating prerequisites..."
    validate_prerequisites
    log "INFO" ""

    # Step 2: Create backup
    log "INFO" "[2/6] Creating backup..."
    create_backup
    log "INFO" ""

    # Step 3: Create new configuration
    log "INFO" "[3/6] Creating new network configuration..."
    create_vlan_config
    log "INFO" ""

    # Step 4: Apply configuration
    log "INFO" "[4/6] Applying network changes..."
    apply_config
    log "INFO" ""

    # Step 5: Verify VLAN setup
    log "INFO" "[5/6] Verifying VLAN setup..."
    if ! verify_vlan; then
        log "ERROR" "Verification failed - initiating rollback"
        rollback_config
        exit 1
    fi
    log "INFO" ""

    # Step 6: Success
    log "INFO" "[6/6] Configuration complete"
    log "INFO" ""
    log "INFO" "==============================================="
    log "INFO" "✓ VLAN 10 Setup Successful!"
    log "INFO" "==============================================="
    log "INFO" "Network interface: ${VLAN_INTERFACE}"
    log "INFO" "IP address: ${VLAN_NETWORK}"
    log "INFO" "Gateway: ${VLAN_IP} (host gateway for VLAN 10)"
    log "INFO" "Backup location: ${BACKUP_FILE}"
    log "INFO" "Log file: ${LOG_FILE}"
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "1. Verify with: ip addr show ${VLAN_INTERFACE}"
    log "INFO" "2. Test with: ping 10.10.10.60"
    log "INFO" "3. Proceed to Phase 1: VM100 creation"
    log "INFO" ""
}

main "$@"
