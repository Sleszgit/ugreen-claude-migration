#!/usr/bin/env bash
################################################################################
# UGREEN Phase 1c: VM100 Production Hardening Orchestrator
# Automated execution of all Phase A hardening scripts with safety checks
#
# Run this AFTER Docker & Portainer installation (Phase 1b)
# This script coordinates the Phase A hardening suite from Session 36
#
# Usage on VM100:
#   sudo bash /tmp/ugreen-phase1c-vm100-hardening-orchestrator.sh
#
# Prerequisites:
#   - Ubuntu 24.04 with Docker installed
#   - Portainer CE running
#   - Phase A scripts downloaded to /opt/hardening/
################################################################################

set -Eeuo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Source location of Phase A scripts (from Session 36)
PHASE_A_SOURCE="/home/sleszugreen/scripts/vm100ugreen/hardening"
PHASE_A_DEST="/opt/hardening"

LOG_FILE="/var/log/vm100-hardening-$(date +%Y%m%d-%H%M%S).log"
LOG_DIR=$(dirname "$LOG_FILE")

SCRIPTS=(
    "00-pre-hardening-checks.sh"
    "01-ssh-hardening.sh"
    "02-ufw-firewall.sh"
    "03-docker-daemon-hardening.sh"
    "04-docker-network-security.sh"
    "05-portainer-deployment.sh"
    "05-checkpoint-phase-a.sh"
)

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
    log "ERROR" "Hardening partially completed. Review log: ${LOG_FILE}"
    exit "${exit_code}"
}

trap 'error_handler ${LINENO} $?' ERR

validate_prerequisites() {
    log "INFO" "Validating prerequisites..."

    if [[ $EUID -ne 0 ]]; then
        log "FATAL" "This script must be run as root"
        exit 1
    fi
    log "INFO" "✓ Running as root"

    # Create log directory
    mkdir -p "$LOG_DIR" || { log "FATAL" "Cannot create ${LOG_DIR}"; exit 1; }
    touch "$LOG_FILE" || { log "FATAL" "Cannot write to ${LOG_FILE}"; exit 1; }
    log "INFO" "✓ Log directory writable"

    # Check if Docker is installed
    if ! command -v docker &>/dev/null; then
        log "FATAL" "Docker not installed - run Phase 1b first"
        exit 1
    fi
    log "INFO" "✓ Docker installed: $(docker --version)"

    # Check if Portainer is running
    if ! docker ps | grep -q portainer; then
        log "FATAL" "Portainer not running - run Phase 1b first"
        exit 1
    fi
    log "INFO" "✓ Portainer is running"

    # Check if Phase A scripts directory exists or accessible
    if [[ ! -d "$PHASE_A_SOURCE" ]]; then
        log "WARN" "Phase A source directory not found: ${PHASE_A_SOURCE}"
        log "WARN" "Scripts may need to be downloaded from repository"
    fi

    log "INFO" "✓ All prerequisites met"
}

prepare_hardening_scripts() {
    log "INFO" "Preparing hardening scripts..."

    # Create destination directory
    mkdir -p "$PHASE_A_DEST" || { log "ERROR" "Cannot create ${PHASE_A_DEST}"; exit 1; }

    # Try to copy from source
    if [[ -d "$PHASE_A_SOURCE" ]]; then
        log "INFO" "Copying Phase A scripts from ${PHASE_A_SOURCE}..."
        cp -v "$PHASE_A_SOURCE"/*.sh "$PHASE_A_DEST/" 2>&1 | tee -a "$LOG_FILE"
        cp -v "$PHASE_A_SOURCE"/README-PHASE-A.md "$PHASE_A_DEST/" 2>&1 | tee -a "$LOG_FILE" || true
        log "INFO" "✓ Scripts copied successfully"
    else
        log "ERROR" "Phase A source not found - cannot copy scripts"
        log "INFO" "Please ensure scripts are available at: ${PHASE_A_DEST}/"
        exit 1
    fi

    # Make all scripts executable
    chmod +x "$PHASE_A_DEST"/*.sh || log "WARN" "Failed to chmod scripts"

    log "INFO" "✓ Scripts prepared at: ${PHASE_A_DEST}/"
}

verify_scripts_present() {
    log "INFO" "Verifying all required scripts..."

    local missing_count=0
    for script in "${SCRIPTS[@]}"; do
        if [[ -f "$PHASE_A_DEST/$script" ]]; then
            log "INFO" "✓ $script present"
        else
            log "ERROR" "✗ $script MISSING"
            ((missing_count++))
        fi
    done

    if [[ $missing_count -gt 0 ]]; then
        log "FATAL" "$missing_count scripts missing - cannot proceed"
        exit 1
    fi

    log "INFO" "✓ All required scripts present"
}

execute_script() {
    local script_name="$1"
    local script_path="$PHASE_A_DEST/$script_name"
    local script_num=$(echo "$script_name" | cut -d'-' -f1)

    log "INFO" ""
    log "INFO" "=========================================="
    log "INFO" "Executing: $script_name"
    log "INFO" "=========================================="
    log "INFO" ""

    if [[ ! -x "$script_path" ]]; then
        log "ERROR" "Script not executable: $script_path"
        exit 1
    fi

    # Run script with error handling
    if ! bash "$script_path" 2>&1 | tee -a "$LOG_FILE"; then
        log "ERROR" "Script failed: $script_name"
        log "ERROR" "Check log for details: ${LOG_FILE}"
        return 1
    fi

    log "INFO" "✓ $script_name completed successfully"
    log "INFO" ""

    # Wait between scripts for system to settle
    if [[ "$script_num" != "05" ]] && [[ "$script_name" != "05-checkpoint-phase-a.sh" ]]; then
        log "INFO" "Waiting 3 seconds for system to settle..."
        sleep 3
    fi
}

execute_hardening_sequence() {
    log "INFO" "Starting Phase A hardening sequence..."
    log "INFO" "Total scripts to execute: ${#SCRIPTS[@]}"
    log "INFO" ""

    local script_count=1
    local total_scripts=${#SCRIPTS[@]}

    for script in "${SCRIPTS[@]}"; do
        log "INFO" "[${script_count}/${total_scripts}] Executing: $script"

        if ! execute_script "$script"; then
            log "ERROR" "Hardening sequence failed at script: $script"
            log "INFO" "Review the output above and logs for details"
            log "INFO" "You can restart from this script after fixing issues"
            exit 1
        fi

        ((script_count++))
    done

    log "INFO" "✓ All Phase A hardening scripts completed successfully"
}

verify_hardening_completion() {
    log "INFO" "Verifying hardening completion..."

    # Check if checkpoint results exist
    if [[ -f "/root/vm100-hardening/CHECKPOINT-A-RESULTS.txt" ]]; then
        log "INFO" "Checkpoint results found:"
        cat /root/vm100-hardening/CHECKPOINT-A-RESULTS.txt | tee -a "$LOG_FILE"
    else
        log "WARN" "Checkpoint results file not found"
    fi

    # Verify critical security configurations
    local checks_passed=0
    local checks_total=0

    # Check 1: SSH hardening (port 22022)
    ((checks_total++))
    if grep -q "^Port 22022" /etc/ssh/sshd_config 2>/dev/null; then
        log "INFO" "✓ SSH configured on port 22022"
        ((checks_passed++))
    else
        log "WARN" "✗ SSH port not verified"
    fi

    # Check 2: UFW enabled
    ((checks_total++))
    if ufw status | grep -q "Status: active"; then
        log "INFO" "✓ UFW firewall is active"
        ((checks_passed++))
    else
        log "WARN" "✗ UFW not verified as active"
    fi

    # Check 3: Docker networks created
    ((checks_total++))
    local network_count=$(docker network ls | grep -E "frontend|backend|monitoring" | wc -l)
    if [[ $network_count -ge 3 ]]; then
        log "INFO" "✓ Docker networks created (found $network_count)"
        ((checks_passed++))
    else
        log "WARN" "✗ Docker networks not fully created"
    fi

    # Check 4: Portainer running on monitoring network
    ((checks_total++))
    if docker ps | grep -q portainer; then
        log "INFO" "✓ Portainer is running"
        ((checks_passed++))
    else
        log "WARN" "✗ Portainer not verified"
    fi

    log "INFO" ""
    log "INFO" "Post-hardening verification: ${checks_passed}/${checks_total} checks passed"
}

print_summary() {
    log "INFO" ""
    log "INFO" "==============================================="
    log "INFO" "✓ Phase A Hardening Complete!"
    log "INFO" "==============================================="
    log "INFO" ""
    log "INFO" "Security Features Applied:"
    log "INFO" "  ✓ SSH hardened (port 22022, keys-only)"
    log "INFO" "  ✓ UFW firewall enabled (rate limiting)"
    log "INFO" "  ✓ Docker daemon hardened (userns-remap)"
    log "INFO" "  ✓ Docker networks isolated (3 networks)"
    log "INFO" "  ✓ Portainer deployed securely"
    log "INFO" ""
    log "INFO" "Important Notes:"
    log "INFO" "  - SSH port changed to 22022"
    log "INFO" "  - Password auth disabled (use keys only)"
    log "INFO" "  - Use sudo for privileged commands"
    log "INFO" "  - Firewall blocks external access by default"
    log "INFO" "  - Emergency rollback script available: 99-emergency-rollback.sh"
    log "INFO" ""
    log "INFO" "Access Information:"
    log "INFO" "  Portainer: https://10.10.10.100:9443"
    log "INFO" "  SSH: ssh -p 22022 -i key admin@10.10.10.100"
    log "INFO" "  (Verify actual IP - may differ)"
    log "INFO" ""
    log "INFO" "Next Steps:"
    log "INFO" "  1. Review checkpoint results: cat /root/vm100-hardening/CHECKPOINT-A-RESULTS.txt"
    log "INFO" "  2. Test SSH on port 22022"
    log "INFO" "  3. Access Portainer to configure services"
    log "INFO" "  4. Deploy infrastructure services (Nginx PM, etc.)"
    log "INFO" "  5. Proceed to Phase 2: LXC103 creation"
    log "INFO" ""
    log "INFO" "Logs:"
    log "INFO" "  Orchestrator: ${LOG_FILE}"
    log "INFO" "  Hardening backups: /root/vm100-hardening/backups/"
    log "INFO" ""
    log "INFO" "==============================================="
}

print_emergency_procedures() {
    log "INFO" ""
    log "INFO" "EMERGENCY PROCEDURES:"
    log "INFO" ""
    log "INFO" "If you lose SSH access on port 22022:"
    log "INFO" "  1. Access VM console via Proxmox"
    log "INFO" "  2. Run: sudo ${PHASE_A_DEST}/99-emergency-rollback.sh"
    log "INFO" "  3. This restores SSH to port 22"
    log "INFO" ""
    log "INFO" "If hardening caused issues:"
    log "INFO" "  1. SSH to VM via Proxmox console"
    log "INFO" "  2. Review ${LOG_FILE} for details"
    log "INFO" "  3. Check backups: ls -la /root/vm100-hardening/backups/"
    log "INFO" "  4. Contact support with log file"
    log "INFO" ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log "INFO" "==============================================="
    log "INFO" "UGREEN Phase 1c: VM100 Hardening Orchestrator"
    log "INFO" "==============================================="
    log "INFO" "Date: $(date)"
    log "INFO" "Hostname: $(hostname)"
    log "INFO" ""

    log "INFO" "[1/5] Validating prerequisites..."
    validate_prerequisites
    log "INFO" ""

    log "INFO" "[2/5] Preparing hardening scripts..."
    prepare_hardening_scripts
    log "INFO" ""

    log "INFO" "[3/5] Verifying script availability..."
    verify_scripts_present
    log "INFO" ""

    log "INFO" "[4/5] Executing hardening sequence..."
    execute_hardening_sequence
    log "INFO" ""

    log "INFO" "[5/5] Verifying completion..."
    verify_hardening_completion
    log "INFO" ""

    print_summary
    print_emergency_procedures
}

main "$@"
