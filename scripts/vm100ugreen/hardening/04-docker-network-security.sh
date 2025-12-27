#!/bin/bash

################################################################################
# Script 04: Docker Network Security
# Purpose: Create isolated Docker networks with segmentation
# Duration: 10 minutes
# Safety: SAFE - Only creates new networks, no service restarts
################################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOCS_DIR="${HOME}/scripts/vm100ugreen/hardening/docs"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Script 04: Docker Network Security${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Verify Docker is running
echo -e "${YELLOW}[STEP 1]${NC} Verifying Docker daemon..."
if ! docker ps >/dev/null 2>&1; then
    echo -e "${RED}✗ Docker daemon not responding${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon is operational${NC}"
echo ""

# Step 2: Create frontend network
echo -e "${YELLOW}[STEP 2]${NC} Creating frontend network (172.18.0.0/16)..."
if docker network ls | grep -q "frontend"; then
    echo -e "${GREEN}✓ Frontend network already exists${NC}"
else
    docker network create \
        --driver bridge \
        --subnet 172.18.0.0/16 \
        --gateway 172.18.0.1 \
        frontend
    echo -e "${GREEN}✓ Frontend network created${NC}"
fi
echo ""

# Step 3: Create backend network
echo -e "${YELLOW}[STEP 3]${NC} Creating backend network (172.19.0.0/16)..."
if docker network ls | grep -q "backend"; then
    echo -e "${GREEN}✓ Backend network already exists${NC}"
else
    docker network create \
        --driver bridge \
        --subnet 172.19.0.0/16 \
        --gateway 172.19.0.1 \
        backend
    echo -e "${GREEN}✓ Backend network created${NC}"
fi
echo ""

# Step 4: Create monitoring network
echo -e "${YELLOW}[STEP 4]${NC} Creating monitoring network (172.20.0.0/16)..."
if docker network ls | grep -q "monitoring"; then
    echo -e "${GREEN}✓ Monitoring network already exists${NC}"
else
    docker network create \
        --driver bridge \
        --subnet 172.20.0.0/16 \
        --gateway 172.20.0.1 \
        monitoring
    echo -e "${GREEN}✓ Monitoring network created${NC}"
fi
echo ""

# Step 5: Display created networks
echo -e "${YELLOW}[STEP 5]${NC} Verifying network creation..."
echo ""
docker network ls | grep -E "(frontend|backend|monitoring)"
echo ""

# Step 6: Create network architecture documentation
echo -e "${YELLOW}[STEP 6]${NC} Creating network architecture documentation..."
mkdir -p "$DOCS_DIR"

cat > "$DOCS_DIR/NETWORK-ARCHITECTURE.md" << 'EOF'
# Docker Network Architecture - VM 100 UGREEN

## Overview
VM 100 uses three isolated Docker networks for security and service segmentation. Containers on different networks cannot communicate unless explicitly connected.

---

## Network Topology

### Frontend Network (172.18.0.0/16)
**Purpose:** Public-facing and user-accessible services

**Gateway:** 172.18.0.1

**Typical Services:**
- Nginx Proxy Manager (NPM)
- Authentik (authentication/SSO)
- Plex Media Server
- Jellyfin
- Other user-facing applications

**Access:** Internal network (192.168.40.0/24) can access these services via published ports

**Example Deployment:**
```bash
docker run -d \
  --name my-frontend-app \
  --network frontend \
  -p 8080:8080 \
  my-app-image
```

---

### Backend Network (172.19.0.0/16)
**Purpose:** Internal services and data stores

**Gateway:** 172.19.0.1

**Typical Services:**
- PostgreSQL databases
- Redis cache
- MongoDB
- Internal APIs
- Message queues

**Access:** ONLY from frontend network (if explicitly connected)

**Security Benefit:** Backend services are isolated from direct frontend access

**Example Deployment:**
```bash
docker run -d \
  --name my-database \
  --network backend \
  -e POSTGRES_PASSWORD=secret \
  postgres:latest
```

---

### Monitoring Network (172.20.0.0/16)
**Purpose:** Logging, monitoring, and observability

**Gateway:** 172.20.0.1

**Typical Services:**
- Portainer CE (container management web UI)
- Loki (log aggregation)
- Grafana (metrics dashboard)
- Netdata (real-time monitoring)
- Prometheus (metrics collection)

**Access:** Internal network only (HTTPS on port 9443 for Portainer)

**Security Benefit:** Monitoring stack is isolated from production containers

**Example Deployment:**
```bash
docker run -d \
  --name portainer \
  --network monitoring \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  portainer/portainer-ce:latest
```

---

## Network Isolation Diagram

```
                    Host Network (192.168.40.0/24)
                              |
                              |
        ┌─────────────────────┼─────────────────────┐
        |                     |                     |
        ▼                     ▼                     ▼
    ┌─────────┐           ┌─────────┐         ┌──────────┐
    │ Frontend │           │ Backend │         │Monitoring│
    │172.18.x.x│           │172.19.x.x│        │172.20.x.x│
    └─────────┘           └─────────┘         └──────────┘
    • NPM                  • PostgreSQL        • Portainer
    • Authentik            • Redis             • Loki
    • Plex/Jellyfin        • Databases         • Grafana
    • User apps            • Internal APIs     • Netdata

        ✗ Cannot reach        ✓ Can connect     ✓ Can connect
        backend directly      if explicitly     if explicitly
                              linked            linked
```

---

## Container Connectivity Examples

### Scenario 1: NPM (Frontend) → Database (Backend)
**Requirement:** Nginx Proxy Manager needs to forward requests to a backend API

```bash
# Create NPM on frontend network
docker run -d --name npm --network frontend nginx:latest

# Create API on backend network
docker run -d --name api --network backend my-api:latest

# Connect NPM to backend network for database access
docker network connect backend npm

# Now NPM can:
#  - Access frontend services via 'frontend' network
#  - Access backend services via 'backend' network
#  - Example: curl http://api:5000 (service discovery)
```

### Scenario 2: Monitoring → Production Services
**Requirement:** Prometheus needs to scrape metrics from all containers

```bash
# Deploy production service on frontend network
docker run -d --name app --network frontend my-app:latest

# Deploy Prometheus on monitoring network
docker run -d --name prometheus --network monitoring prom/prometheus:latest

# Connect Prometheus to frontend network for scraping
docker network connect frontend prometheus

# Prometheus can now scrape metrics from app on frontend network
```

### Scenario 3: Backend Service → Multiple Networks
**Requirement:** Redis cache accessed by both frontend and backend services

```bash
# Deploy Redis on backend network
docker run -d --name redis --network backend redis:latest

# Connect to frontend (for frontend apps that need cache)
docker network connect backend redis

# Now frontend services can reach redis via hostname 'redis'
# And backend services can reach redis via hostname 'redis'
```

---

## Service Discovery

Docker provides built-in DNS for containers on the same network.

**Rules:**
- Containers can reach other containers by **service name** (not IP)
- Example: `curl http://database:5432` (if both on same network)
- DNS is automatic - no configuration needed
- Cannot resolve containers on different networks unless explicitly connected

**Testing Connectivity:**
```bash
# Enter running container
docker exec -it my-container bash

# Test connection to service on same network
ping database

# Test connection to service on different network (will fail)
ping api  # ✗ Unknown host (different network)

# But if container is connected to both networks
ping api  # ✓ Resolves (both networks connected)
```

---

## Deploying Containers

### Decision Tree

1. **Is it user-facing or client-accessible?**
   - Yes → Deploy on **frontend** network
   - No → Continue to step 2

2. **Is it a database, cache, or internal service?**
   - Yes → Deploy on **backend** network
   - No → Continue to step 3

3. **Is it monitoring, logging, or observability?**
   - Yes → Deploy on **monitoring** network
   - No → Deploy on **frontend** network (safest default)

### Portainer Deployment Example

In Portainer web UI:
1. Navigate to: Containers → Create Container
2. Set Image: `my-app:latest`
3. Set Name: `my-container`
4. Set Network: `frontend` (or `backend` or `monitoring`)
5. Configure Ports: `-p 8080:8080` (if needed)
6. Create Container

Portainer will automatically handle network attachment.

---

## Troubleshooting Network Issues

### Container Cannot Reach Another Container

**Checklist:**
1. Are both containers on the same network?
   - Use: `docker network inspect frontend` to verify
   - Look for "Containers" section
2. Is the container name spelled correctly?
   - Container names are case-sensitive
   - Use: `docker ps` to verify exact names
3. Is the connection being blocked by a firewall?
   - Check host firewall: `sudo ufw status`
   - Check container security options (AppArmor, seccomp)

### Network Has No Containers

**Normal:** Networks can exist empty if no containers are deployed yet

**Verification:**
```bash
docker network inspect frontend
# If "Containers": {} is empty, no containers use this network
```

### Cannot Access Published Port

**Example:** Port 8080 is published but connection refused

**Checklist:**
1. Is the service actually listening?
   - Use: `docker logs my-container` to check for errors
2. Is the port correctly published?
   - Use: `docker ps` and verify port mapping
3. Is the firewall blocking the port?
   - Check: `sudo ufw status`
   - Add rule: `sudo ufw allow 8080/tcp`
4. Is it listening on localhost only?
   - Check container logs for binding address
   - May need to configure service to listen on 0.0.0.0

---

## Best Practices

1. **Always use networks:** Never rely on the default bridge network
2. **One service per container:** Follow single-responsibility principle
3. **Use service names:** Reference containers by name, not IP (IPs can change)
4. **Document connections:** Note which containers need to communicate
5. **Isolate by tier:** Frontend ≠ Backend ≠ Monitoring
6. **Connect explicitly:** Only connect containers that actually need to communicate

---

## Summary Table

| Network | Subnet | Purpose | Services | Access |
|---------|--------|---------|----------|--------|
| **frontend** | 172.18.0.0/16 | Public/UI services | NPM, Authentik, Plex, Jellyfin | External + internal |
| **backend** | 172.19.0.0/16 | Data & internal services | Databases, APIs, cache | Internal only |
| **monitoring** | 172.20.0.0/16 | Observability | Portainer, Loki, Grafana, Netdata | Internal HTTPS |

---

**Last Updated:** $(date)
**Created By:** vm100-hardening Script 04
EOF

echo -e "${GREEN}✓ Network architecture documentation created${NC}"
echo -e "  Location: $DOCS_DIR/NETWORK-ARCHITECTURE.md"
echo ""

# Step 7: Display completion summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}DOCKER NETWORK SECURITY COMPLETE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} Frontend network created (172.18.0.0/16)"
echo -e "${GREEN}✓${NC} Backend network created (172.19.0.0/16)"
echo -e "${GREEN}✓${NC} Monitoring network created (172.20.0.0/16)"
echo -e "${GREEN}✓${NC} Network architecture documented"
echo ""
echo -e "${YELLOW}NETWORK ISOLATION:${NC}"
echo "  • Containers on different networks CANNOT communicate"
echo "  • Must explicitly connect containers that need to communicate"
echo "  • Service discovery via container names (automatic DNS)"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "When deploying containers, specify network:"
echo "  docker run -d --name my-app --network frontend my-image"
echo ""
echo "View available networks:"
echo "  docker network ls"
echo ""
echo -e "${GREEN}Script 04 complete! Proceed to Script 05.${NC}"
