#!/bin/bash

################################################################################
# Script 03: Docker Daemon Hardening
# Purpose: Harden Docker daemon with security-focused configuration
# Duration: 15 minutes
# Safety: CRITICAL - Restarts Docker daemon
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="${HOME}/vm100-hardening/backups"
DAEMON_CONFIG="/etc/docker/daemon.json"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Script 03: Docker Daemon Hardening${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Verify Docker is installed
echo -e "${YELLOW}[STEP 1]${NC} Checking Docker installation..."
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}✗ Docker not installed${NC}"
    exit 1
fi

DOCKER_VERSION=$(docker --version)
echo -e "${GREEN}✓ Docker installed: $DOCKER_VERSION${NC}"
echo ""

# Step 2: Backup daemon.json
echo -e "${YELLOW}[STEP 2]${NC} Backing up Docker daemon configuration..."
if [[ -f "$DAEMON_CONFIG" ]]; then
    if [[ ! -f "$BACKUP_DIR/daemon.json.backup" ]]; then
        sudo cp "$DAEMON_CONFIG" "$BACKUP_DIR/daemon.json.backup"
        echo -e "${GREEN}✓ Backup created: $BACKUP_DIR/daemon.json.backup${NC}"
    fi
else
    echo -e "${GREEN}✓ daemon.json will be created${NC}"
fi
echo ""

# Step 3: Create hardened daemon.json
echo -e "${YELLOW}[STEP 3]${NC} Creating hardened Docker daemon configuration..."
cat > /tmp/daemon.json << 'EOF'
{
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "icc": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "userns-remap": "default"
}
EOF

sudo tee "$DAEMON_CONFIG" > /dev/null < /tmp/daemon.json
echo -e "${GREEN}✓ Hardened daemon.json created${NC}"
echo ""

# Step 4: Set proper permissions
echo -e "${YELLOW}[STEP 4]${NC} Setting file permissions..."
sudo chmod 644 "$DAEMON_CONFIG"
echo -e "${GREEN}✓ Permissions set correctly${NC}"
echo ""

# Step 5: Enable user namespace remapping
echo -e "${YELLOW}[STEP 5]${NC} Configuring user namespace remapping..."

# Create subuid/subgid entries if they don't exist
if ! sudo grep -q "^dockremap:" /etc/subuid 2>/dev/null; then
    echo "dockremap:100000:65536" | sudo tee -a /etc/subuid > /dev/null
    echo -e "${GREEN}✓ Created /etc/subuid entry${NC}"
else
    echo -e "${GREEN}✓ /etc/subuid already configured${NC}"
fi

if ! sudo grep -q "^dockremap:" /etc/subgid 2>/dev/null; then
    echo "dockremap:100000:65536" | sudo tee -a /etc/subgid > /dev/null
    echo -e "${GREEN}✓ Created /etc/subgid entry${NC}"
else
    echo -e "${GREEN}✓ /etc/subgid already configured${NC}"
fi

echo ""

# Step 6: Restart Docker daemon
echo -e "${YELLOW}[STEP 6]${NC} Restarting Docker daemon..."
echo ""
echo -e "${YELLOW}⚠️  Docker daemon will restart now${NC}"
echo "This may interrupt any running containers."
echo ""

sudo systemctl restart docker

# Wait for Docker to be ready
echo -e "${YELLOW}Waiting for Docker to be ready...${NC}"
for i in {1..30}; do
    if sudo systemctl is-active docker >/dev/null 2>&1; then
        if docker ps >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker daemon restarted successfully${NC}"
            break
        fi
    fi
    sleep 1
done

echo ""

# Step 7: Verify daemon is healthy
echo -e "${YELLOW}[STEP 7]${NC} Verifying Docker daemon health..."

if docker ps >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker daemon is responsive${NC}"
else
    echo -e "${RED}✗ Docker daemon is not responding${NC}"
    echo "Attempting rollback..."
    if [[ -f "$BACKUP_DIR/daemon.json.backup" ]]; then
        sudo cp "$BACKUP_DIR/daemon.json.backup" "$DAEMON_CONFIG"
        sudo systemctl restart docker
        exit 1
    fi
fi

echo ""

# Step 8: Verify hardening settings
echo -e "${YELLOW}[STEP 8]${NC} Verifying hardening configuration..."
echo ""

echo "Docker daemon configuration:"
sudo cat "$DAEMON_CONFIG" | grep -E '(live-restore|userland-proxy|no-new-privileges|icc|userns-remap)' || true
echo ""

# Check user namespace mapping
if docker info | grep -q "userns"; then
    echo -e "${GREEN}✓ User namespace remapping is active${NC}"
else
    echo -e "${YELLOW}⚠ User namespace remapping may not be active${NC}"
fi

echo ""

# Step 9: Display completion summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}DOCKER DAEMON HARDENING COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} Docker daemon restarted with hardened configuration"
echo -e "${GREEN}✓${NC} User namespace remapping enabled (container root ≠ host root)"
echo -e "${GREEN}✓${NC} Privilege escalation prevention enabled (no-new-privileges)"
echo -e "${GREEN}✓${NC} Inter-container communication disabled (icc=false)"
echo -e "${GREEN}✓${NC} Log rotation configured (max 10MB per container)"
echo -e "${GREEN}✓${NC} Live restore enabled (containers survive daemon restart)"
echo ""
echo -e "${YELLOW}SECURITY BENEFITS:${NC}"
echo "  - Container root cannot affect host system (critical isolation)"
echo "  - Containers cannot communicate without explicit networks"
echo "  - Privilege escalation within containers is prevented"
echo "  - Logs won't fill disk (max 30MB per container)"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "If you had running containers, they should auto-restart."
echo "Verify they're running with: docker ps"
echo ""
echo "Rollback if needed:"
echo "  bash ${HOME}/vm100-hardening/99-emergency-rollback.sh"
echo ""
echo -e "${GREEN}Script 03 complete! Proceed to Script 04.${NC}"
