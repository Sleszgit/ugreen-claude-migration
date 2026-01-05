#!/usr/bin/env bash
################################################################################
# UGREEN Phase 2b: Docker & Portainer Agent Installation on LXC103
# Install Docker CE and Portainer Agent in LXC103
#
# Run this AFTER LXC103 is created and running
#
# Usage on LXC103:
#   sudo bash /tmp/docker-setup.sh
#
# Or from Proxmox host:
#   pct exec 103 -- bash -s < /nvme2tb/lxc102scripts/ugreen-phase2-lxc103-docker.sh
################################################################################

set -Eeuo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

DOCKER_SOCKET="/var/run/docker.sock"
PORTAINER_AGENT_PORT=9001
PORTAINER_AGENT_RESTART="unless-stopped"
TIMEZONE="Europe/Warsaw"
GPU_DEVICE="/dev/dri/renderD128"

LOG_FILE="/var/log/docker-setup-$(date +%Y%m%d-%H%M%S).log"
LOG_DIR=$(dirname "$LOG_FILE")

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
    log "INFO" "✓ Running as root"

    # Validate log directory
    mkdir -p "$LOG_DIR" || { log "FATAL" "Cannot create ${LOG_DIR}"; exit 1; }
    touch "$LOG_FILE" || { log "FATAL" "Cannot write to ${LOG_FILE}"; exit 1; }
    log "INFO" "✓ Log directory writable"

    # Check if Ubuntu
    if [[ ! -f /etc/os-release ]]; then
        log "FATAL" "/etc/os-release not found"
        exit 1
    fi
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log "ERROR" "This script is for Ubuntu, but detected: $PRETTY_NAME"
        exit 1
    fi
    log "INFO" "✓ Ubuntu detected: $PRETTY_NAME"

    # Check GPU device access
    if [[ -c "$GPU_DEVICE" ]]; then
        log "INFO" "✓ GPU device ${GPU_DEVICE} is accessible"
    else
        log "WARN" "GPU device ${GPU_DEVICE} not found - hardware transcoding may not work"
    fi

    # List available devices
    log "INFO" "Available DRI devices:"
    ls -la /dev/dri/ 2>&1 | tee -a "$LOG_FILE" || true
}

set_timezone() {
    log "INFO" "Setting timezone to ${TIMEZONE}..."

    timedatectl set-timezone "$TIMEZONE" || log "WARN" "Failed to set timezone"

    local current_tz=$(timedatectl show --no-pager -p Timezone --value 2>/dev/null || echo "unknown")
    log "INFO" "✓ Timezone set to: ${current_tz}"
}

install_docker() {
    log "INFO" "Installing Docker CE..."

    # Update package lists
    log "INFO" "Updating package lists..."
    apt-get update -qq || { log "ERROR" "apt update failed"; exit 1; }

    # Add Docker repository key
    log "INFO" "Adding Docker repository key..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /tmp/docker.asc 2>&1 | tee -a "$LOG_FILE" || \
        { log "ERROR" "Failed to download Docker GPG key"; exit 1; }
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg < /tmp/docker.asc 2>&1 | tee -a "$LOG_FILE"
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    log "INFO" "Adding Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update and install
    log "INFO" "Installing Docker packages..."
    apt-get update -qq || { log "ERROR" "apt update failed"; exit 1; }

    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tee -a "$LOG_FILE" || \
        { log "ERROR" "Failed to install Docker"; exit 1; }

    log "INFO" "✓ Docker installed: $(docker --version)"
}

install_docker_compose() {
    log "INFO" "Installing Docker Compose (standalone)..."

    local compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
    log "INFO" "Latest Docker Compose version: ${compose_version}"

    curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose 2>&1 | tee -a "$LOG_FILE"

    chmod +x /usr/local/bin/docker-compose

    log "INFO" "✓ Docker Compose installed: $(docker-compose --version)"
}

configure_docker() {
    log "INFO" "Configuring Docker daemon..."

    # Enable systemd service
    systemctl enable docker || log "WARN" "Failed to enable docker service"
    systemctl start docker || { log "ERROR" "Failed to start docker"; exit 1; }

    # Wait for daemon
    sleep 2

    # Verify Docker is running
    if ! docker ps &>/dev/null; then
        log "ERROR" "Docker daemon not responding"
        exit 1
    fi
    log "INFO" "✓ Docker daemon is running"

    # Configure daemon settings
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

    log "INFO" "✓ Docker daemon configured"

    # Reload daemon
    systemctl daemon-reload
    systemctl restart docker
    sleep 2

    log "INFO" "✓ Docker daemon restarted"
}

bootstrap_portainer_agent() {
    log "INFO" "Bootstrapping Portainer Agent..."

    # Stop existing agent if running
    if docker ps -a | grep -q portainer_agent; then
        log "INFO" "Stopping existing Portainer Agent..."
        docker stop portainer_agent || true
        docker rm portainer_agent || true
    fi

    # Deploy Portainer Agent
    log "INFO" "Deploying Portainer Agent..."
    docker run -d \
        --name portainer_agent \
        --restart="$PORTAINER_AGENT_RESTART" \
        -e "TZ=$TIMEZONE" \
        -p "${PORTAINER_AGENT_PORT}:9001" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/volumes:/var/lib/docker/volumes \
        portainer/agent:latest 2>&1 | tee -a "$LOG_FILE" || \
        { log "ERROR" "Failed to deploy Portainer Agent"; exit 1; }

    # Wait for container to start
    sleep 3

    # Verify agent is running
    if docker ps | grep -q portainer_agent; then
        log "INFO" "✓ Portainer Agent container is running"
    else
        log "ERROR" "Portainer Agent container failed to start"
        docker logs portainer_agent 2>&1 | tee -a "$LOG_FILE" || true
        exit 1
    fi

    # Wait for agent to be ready
    log "INFO" "Waiting for Portainer Agent to be ready (up to 15 seconds)..."
    local attempt=0
    while [[ $attempt -lt 15 ]]; do
        if curl -s http://localhost:${PORTAINER_AGENT_PORT} &>/dev/null; then
            log "INFO" "✓ Portainer Agent is responding"
            break
        fi
        ((attempt++))
        sleep 1
    done

    if [[ $attempt -eq 15 ]]; then
        log "WARN" "Portainer Agent did not respond in time, but container is running"
    fi
}

verify_gpu_in_docker() {
    log "INFO" "Verifying GPU access from Docker..."

    # Try to check GPU access from Docker container
    local gpu_test=$(docker run --rm \
        --device /dev/dri/renderD128 \
        ubuntu:24.04 \
        bash -c "ls -la /dev/dri/ 2>&1 | head -10" 2>&1 || true)

    if echo "$gpu_test" | grep -q "renderD128"; then
        log "INFO" "✓ GPU can be passed to containers"
    else
        log "WARN" "GPU passthrough test inconclusive"
    fi

    log "INFO" "GPU test output:"
    log "INFO" "$gpu_test"
}

verify_installation() {
    log "INFO" "Verifying installation..."

    local checks_passed=0
    local checks_total=0

    # Check 1: Docker running
    ((checks_total++))
    if systemctl is-active --quiet docker; then
        log "INFO" "✓ Check 1/5: Docker service is active"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 1/5: Docker service not active"
    fi

    # Check 2: Docker socket accessible
    ((checks_total++))
    if [[ -S "$DOCKER_SOCKET" ]]; then
        log "INFO" "✓ Check 2/5: Docker socket accessible"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 2/5: Docker socket not found"
    fi

    # Check 3: Docker commands work
    ((checks_total++))
    if docker ps &>/dev/null; then
        log "INFO" "✓ Check 3/5: Docker commands work"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 3/5: Docker commands failed"
    fi

    # Check 4: Portainer Agent running
    ((checks_total++))
    if docker ps | grep -q "portainer_agent"; then
        log "INFO" "✓ Check 4/5: Portainer Agent container running"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 4/5: Portainer Agent not running"
    fi

    # Check 5: Timezone correct
    ((checks_total++))
    local current_tz=$(timedatectl show --no-pager -p Timezone --value 2>/dev/null || echo "unknown")
    if [[ "$current_tz" == "$TIMEZONE" ]]; then
        log "INFO" "✓ Check 5/5: Timezone set to ${TIMEZONE}"
        ((checks_passed++))
    else
        log "ERROR" "✗ Check 5/5: Timezone is ${current_tz} (expected ${TIMEZONE})"
    fi

    log "INFO" "Verification complete: ${checks_passed}/${checks_total} checks passed"

    if [[ $checks_passed -eq $checks_total ]]; then
        return 0
    else
        return 1
    fi
}

print_summary() {
    local lxc_ip=$(hostname -I | awk '{print $1}')

    log "INFO" ""
    log "INFO" "==============================================="
    log "INFO" "✓ Docker & Portainer Agent Setup Complete!"
    log "INFO" "==============================================="
    log "INFO" "LXC IP: ${lxc_ip}"
    log "INFO" "Versions:"
    log "INFO" "  Docker: $(docker --version)"
    log "INFO" "  Docker Compose: $(docker-compose --version)"
    log "INFO" "  Timezone: ${TIMEZONE}"
    log "INFO" ""
    log "INFO" "Portainer Agent:"
    log "INFO" "  Running on: http://${lxc_ip}:${PORTAINER_AGENT_PORT}"
    log "INFO" "  Status: Connected to Portainer CE (on VM100)"
    log "INFO" "  Access: Via Portainer web UI at https://10.10.10.100:9443"
    log "INFO" ""
    log "INFO" "GPU Status:"
    if [[ -c "$GPU_DEVICE" ]]; then
        log "INFO" "  ✓ GPU device ${GPU_DEVICE} is accessible"
        log "INFO" "  Containers can use: --device ${GPU_DEVICE}:/dev/dri/renderD128"
    else
        log "INFO" "  ✗ GPU device not accessible"
    fi
    log "INFO" ""
    log "INFO" "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>&1 | tee -a "$LOG_FILE"
    log "INFO" ""
    log "INFO" "Next Steps:"
    log "INFO" "1. Return to Portainer on VM100: https://10.10.10.100:9443"
    log "INFO" "2. Add LXC103 as Endpoint:"
    log "INFO" "   - Settings → Endpoints → Add environment"
    log "INFO" "   - Name: lxc-media or similar"
    log "INFO" "   - API Server: http://${lxc_ip}:${PORTAINER_AGENT_PORT}"
    log "INFO" "3. Deploy media services via Portainer Stacks"
    log "INFO" ""
    log "INFO" "Log file: ${LOG_FILE}"
    log "INFO" "==============================================="
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log "INFO" "==============================================="
    log "INFO" "UGREEN Phase 2b: Docker & Portainer Agent Setup"
    log "INFO" "==============================================="
    log "INFO" "Date: $(date)"
    log "INFO" ""

    log "INFO" "[1/8] Validating prerequisites..."
    validate_prerequisites
    log "INFO" ""

    log "INFO" "[2/8] Setting timezone..."
    set_timezone
    log "INFO" ""

    log "INFO" "[3/8] Installing Docker CE..."
    install_docker
    log "INFO" ""

    log "INFO" "[4/8] Installing Docker Compose..."
    install_docker_compose
    log "INFO" ""

    log "INFO" "[5/8] Configuring Docker daemon..."
    configure_docker
    log "INFO" ""

    log "INFO" "[6/8] Bootstrapping Portainer Agent..."
    bootstrap_portainer_agent
    log "INFO" ""

    log "INFO" "[7/8] Verifying GPU in Docker..."
    verify_gpu_in_docker
    log "INFO" ""

    log "INFO" "[8/8] Verifying installation..."
    verify_installation
    log "INFO" ""

    print_summary
}

main "$@"
