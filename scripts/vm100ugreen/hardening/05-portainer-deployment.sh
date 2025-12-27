#!/bin/bash

################################################################################
# Script 05: Portainer Deployment
# Purpose: Deploy Portainer CE for web UI container management
# Duration: 10 minutes
# Safety: SAFE - Deploys container on monitoring network
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Script 05: Portainer Deployment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Verify Docker and monitoring network
echo -e "${YELLOW}[STEP 1]${NC} Verifying prerequisites..."

if ! docker ps >/dev/null 2>&1; then
    echo -e "${RED}✗ Docker daemon not responding${NC}"
    exit 1
fi

if ! docker network ls | grep -q "monitoring"; then
    echo -e "${RED}✗ Monitoring network not found (run Script 04 first)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker daemon operational${NC}"
echo -e "${GREEN}✓ Monitoring network exists${NC}"
echo ""

# Step 2: Check if Portainer already exists
echo -e "${YELLOW}[STEP 2]${NC} Checking for existing Portainer installation..."

if docker ps -a | grep -q "portainer"; then
    echo -e "${YELLOW}⚠ Portainer container already exists${NC}"
    if docker ps | grep -q "portainer"; then
        echo -e "${GREEN}✓ Portainer is already running${NC}"
        EXISTING_PORTAINER=true
    else
        echo -e "${YELLOW}Portainer is stopped. Starting...${NC}"
        docker start portainer
        EXISTING_PORTAINER=true
    fi
else
    EXISTING_PORTAINER=false
    echo -e "${GREEN}✓ Fresh Portainer deployment${NC}"
fi

echo ""

# Step 3: Pull Portainer image
if [[ "$EXISTING_PORTAINER" == "false" ]]; then
    echo -e "${YELLOW}[STEP 3]${NC} Pulling Portainer image..."
    docker pull portainer/portainer-ce:latest
    echo -e "${GREEN}✓ Portainer image pulled${NC}"
    echo ""
fi

# Step 4: Create Portainer data volume
echo -e "${YELLOW}[STEP 4]${NC} Creating Portainer data volume..."

if docker volume ls | grep -q "portainer_data"; then
    echo -e "${GREEN}✓ Volume 'portainer_data' already exists${NC}"
else
    docker volume create portainer_data
    echo -e "${GREEN}✓ Volume 'portainer_data' created${NC}"
fi

echo ""

# Step 5: Deploy Portainer container
if [[ "$EXISTING_PORTAINER" == "false" ]]; then
    echo -e "${YELLOW}[STEP 5]${NC} Deploying Portainer container..."
    echo "This may take 10-15 seconds..."
    echo ""

    docker run -d \
        --name portainer \
        --restart=unless-stopped \
        --network monitoring \
        -p 9443:9443 \
        -p 9000:9000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        --security-opt=no-new-privileges:true \
        --read-only \
        --tmpfs /tmp \
        portainer/portainer-ce:latest

    echo -e "${GREEN}✓ Portainer container deployed${NC}"
    echo ""

    # Wait for Portainer to be ready
    echo -e "${YELLOW}[STEP 6]${NC} Waiting for Portainer to be ready..."
    TIMEOUT=30
    ELAPSED=0
    while [[ $ELAPSED -lt $TIMEOUT ]]; do
        if curl -sk https://localhost:9443 >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Portainer is ready${NC}"
            break
        fi
        echo -n "."
        sleep 1
        ((ELAPSED++))
    done

    if [[ $ELAPSED -ge $TIMEOUT ]]; then
        echo -e "${YELLOW}⚠ Portainer startup may still be in progress${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}[STEP 5-6]${NC} Portainer already running, skipping deployment${NC}"
    echo ""
fi

# Step 7: Verify Portainer is running
echo -e "${YELLOW}[STEP 7]${NC} Verifying Portainer health..."

if docker ps | grep -q "portainer"; then
    echo -e "${GREEN}✓ Portainer container is running${NC}"
    
    # Get container details
    PORT_STATUS=$(docker ps --filter "name=portainer" --format "{{.Status}}")
    echo "  Status: $PORT_STATUS"
else
    echo -e "${RED}✗ Portainer container is not running${NC}"
    echo "Check logs: docker logs portainer"
    exit 1
fi

echo ""

# Step 8: Display access information
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PORTAINER DEPLOYMENT COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} Portainer deployed on monitoring network"
echo -e "${GREEN}✓${NC} HTTPS port: 9443"
echo -e "${GREEN}✓${NC} Hardened configuration applied:"
echo "   - Read-only filesystem"
echo "   - No privilege escalation (no-new-privileges)"
echo "   - Automatic restart on failure"
echo ""
echo -e "${YELLOW}ACCESS PORTAINER:${NC}"
echo "  Web UI: https://192.168.40.60:9443"
echo ""
echo -e "${YELLOW}FIRST LOGIN:${NC}"
echo "  1. Open browser: https://192.168.40.60:9443"
echo "  2. Accept self-signed certificate warning"
echo "  3. Create admin account (strong password!)"
echo "  4. Verify Docker environment is connected"
echo "  5. Explore Containers, Images, Networks, Volumes tabs"
echo ""
echo -e "${YELLOW}CONTAINER MANAGEMENT:${NC}"
echo "  In Portainer, you can:"
echo "  • View all containers and their status"
echo "  • Start/stop/restart containers"
echo "  • View container logs in real-time"
echo "  • Deploy new containers with GUI"
echo "  • Manage networks, volumes, images"
echo "  • Access container consoles"
echo ""
echo -e "${YELLOW}USEFUL DOCKER COMMANDS:${NC}"
echo "  docker ps                      # List running containers"
echo "  docker logs portainer          # View Portainer logs"
echo "  docker network ls              # List Docker networks"
echo "  docker exec -it portainer bash # Access Portainer shell"
echo ""
echo -e "${GREEN}Script 05 complete! Proceed to Checkpoint Script.${NC}"
