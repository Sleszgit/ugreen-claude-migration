# Session 124: VM100 Services Deployment - CLI Analysis & Automation Strategy

**Date:** 14 January 2026
**User:** sleszgit
**Context:** VM100 production-ready, exploring CLI-based service deployment alternatives to Portainer web UI

---

## 🎯 Session Objectives

1. ✅ Recall comprehensive VM100 services list from previous sessions
2. ✅ Identify CLI-based deployment methods (non-UI)
3. ✅ Analyze Portainer API capabilities
4. ✅ Document docker-compose and automation patterns
5. ✅ Plan Phase 3 service deployment strategy

---

## 📋 VM100 Services Inventory (Confirmed)

### **Infrastructure Services (VM100 @ 10.10.10.100)** - 10 services
1. **Nginx Proxy Manager** - reverse proxy/routing (✅ DEPLOYED via migration)
2. **Authentik** - SSO/OAuth2 (planned)
3. **Netbird** - mesh VPN (planned)
4. **Paperless-ngx** - document management (planned)
5. **SimpleLogin** - email aliasing (planned)
6. **Uptime Kuma** - uptime/status monitoring (planned)
7. **Stirling PDF** - PDF utilities (planned)
8. **Pairdrop** - file sharing (planned)
9. **Nextcloud/Nextexplorer** - file browser (planned)
10. **UniFi Network Management** - network control (planned)

### **Media Services (LXC103)** - 7 services
11. **Plex** - transcoding with Intel QuickSync GPU
12. **Jellyfin** - transcoding with Intel QuickSync GPU
13. **Sonarr** - TV show automation
14. **Radarr** - movie automation
15. **Prowlarr** - indexer management
16. **Bazarr** - subtitle automation
17. **Lidarr** - music automation

**Deployment Status:**
- ✅ Portainer CE (container orchestration platform)
- ✅ Nginx Proxy Manager (migrated from NAS in Session 109)
- ⏳ 8 additional infrastructure services (not yet deployed)
- ⏳ 7 media services on LXC103 (not yet deployed)

---

## 🔍 CLI Deployment Methods Analysis

### **Method 1: Portainer REST API (Programmatic)**
**Complexity:** High | **Automation:** Excellent | **Learning Curve:** Steep

**Capabilities:**
- Create/manage stacks programmatically
- Deploy containers via curl/HTTP requests
- Full API token-based authentication
- Manage multiple environments (VM100, LXC103, etc.)

**Implementation Pattern:**
```bash
# 1. Authenticate and get API token
TOKEN=$(curl -X POST https://10.10.10.100:9443/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@example.com","password":"PASSWORD"}' \
  -k | jq -r '.jwt')

# 2. Deploy stack via API
curl -X POST https://10.10.10.100:9443/api/stacks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"Name":"service-name","StackFileContent":"...docker-compose..."}' \
  -k
```

**Status in Codebase:** Not implemented yet. Documentation exists for Portainer setup but API integration not established.

---

### **Method 2: Docker Compose (Recommended)**
**Complexity:** Low | **Automation:** Good | **Learning Curve:** Minimal

**Advantages:**
- Native Docker tool (already installed in VM100)
- Version-controllable (commit .yml files to git)
- Reproducible deployments
- Easy rollback via docker-compose down
- No additional tools needed

**Implementation Pattern:**
```bash
# SSH to VM100
ssh -p 22022 admin@10.10.10.100

# Deploy service from docker-compose file
docker compose -f /path/to/service/docker-compose.yml up -d

# View status
docker compose -f /path/to/service/docker-compose.yml ps

# Stop/restart
docker compose -f /path/to/service/docker-compose.yml down
docker compose -f /path/to/service/docker-compose.yml up -d
```

**Current Infrastructure:**
- `/mnt/lxc102scripts/docker-compose.yml` - NPM backup reference
- `/home/ubuntu/docker/nginx-proxy-manager/docker-compose.yml` - NPM production

**Existing Scripts Using This Pattern:**
- `ugreen-phase1-vm100-docker.sh` - Docker CE installation (uses docker run)
- `ugreen-phase2-lxc103-docker.sh` - LXC103 Docker setup (uses docker run)

**Status:** Partially implemented. Nginx PM uses docker-compose, but other services not yet structured.

---

### **Method 3: Docker CLI (Most Direct)**
**Complexity:** Medium | **Automation:** Good | **Learning Curve:** Low

**Implementation Pattern:**
```bash
ssh -p 22022 admin@10.10.10.100

# Deploy single container
docker run -d \
  --name service-name \
  --network frontend \
  -p 8080:8080 \
  -e VAR=value \
  image:latest

# Container management
docker ps
docker logs service-name
docker exec -it service-name /bin/bash
docker stop/start/restart service-name
```

**Status:** Used in Phase 1b Portainer deployment (05-portainer-deployment.sh).

---

## 📊 Comparison Matrix

| Aspect | Portainer API | Docker Compose | Docker CLI |
|--------|---------------|----------------|-----------|
| **Setup Complexity** | High | Low | Low |
| **Automation Friendly** | Excellent | Excellent | Good |
| **Version Control** | Partial (via git) | Excellent | Partial |
| **Learning Curve** | Steep | Minimal | Minimal |
| **Multi-service** | Yes | Yes | Per-container |
| **Secrets Management** | Portainer secrets | .env files | Environment vars |
| **Scaling** | API orchestration | Stack orchestration | Manual |
| **Monitoring** | Web UI + API | Via docker tools | CLI/logs |
| **Existing Code** | None | Partial (NPM) | Phase 1b |
| **Recommended?** | For CI/CD | **✅ For this project** | Basic ops |

---

## 🏗️ Current Deployment Architecture

### **What Exists (Session 123 Status)**

```
VM100 (10.10.10.100) - VLAN10
├── Docker Engine 29.1.3 (installed)
├── Docker Compose 5.0.1 (installed)
├── Portainer CE (running on 9443, monitoring network)
├── Nginx Proxy Manager (running on 80/443, frontend network)
├── Docker Networks
│   ├── frontend (172.18.0.0/16)
│   ├── backend (172.19.0.0/16)
│   └── monitoring (172.20.0.0/16)
└── Hardening (UFW, SSH on 22022, Fail2ban)

LXC103 (GPU-enabled)
├── Docker Engine (installed Phase 2b)
├── Portainer Agent (running on 9001)
└── Ready for media services
```

### **Docker Compose File Inventory**

**Currently Tracked:**
- ✅ `/mnt/lxc102scripts/docker-compose.yml` - NPM backup reference
- ✅ `/home/ubuntu/docker/nginx-proxy-manager/docker-compose.yml` - NPM production

**Missing (Need to Create):**
- ❌ Authentik docker-compose.yml
- ❌ Netbird docker-compose.yml
- ❌ Paperless-ngx docker-compose.yml
- ❌ SimpleLogin docker-compose.yml
- ❌ Uptime Kuma docker-compose.yml
- ❌ Stirling-PDF docker-compose.yml
- ❌ Pairdrop docker-compose.yml
- ❌ Nextcloud docker-compose.yml
- ❌ UniFi Network docker-compose.yml
- ❌ Media services (Plex, Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, Lidarr)

---

## 🚀 Recommended Deployment Strategy (Phase 3)

### **Architecture**
```
Phase 3: Service Deployment (CLI-based)
├── Phase 3a: Create docker-compose files
│   ├── /mnt/lxc102scripts/services/authentik/docker-compose.yml
│   ├── /mnt/lxc102scripts/services/netbird/docker-compose.yml
│   ├── /mnt/lxc102scripts/services/paperless/docker-compose.yml
│   ├── ... (8 more infrastructure services)
│   └── /mnt/lxc102scripts/services/media/ (7 services)
│
├── Phase 3b: Create orchestrator script
│   └── ugreen-phase3-deploy-services.sh
│       ├── Validates docker-compose syntax
│       ├── Creates required networks
│       ├── Deploys each service
│       ├── Validates health checks
│       └── Generates deployment report
│
└── Phase 3c: Document each service
    ├── SERVICE-AUTHENTIK-DEPLOYMENT.md
    ├── SERVICE-NETBIRD-DEPLOYMENT.md
    └── ... (one per service)
```

### **Implementation Workflow**

**Step 1: Organize Service Files**
```
/mnt/lxc102scripts/services/
├── authentik/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
├── netbird/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
... (etc for each service)
```

**Step 2: Create Orchestrator Script**
```bash
#!/usr/bin/env bash
set -Eeuo pipefail

SERVICES_DIR="/mnt/lxc102scripts/services"

for service_dir in "$SERVICES_DIR"/*; do
    service=$(basename "$service_dir")
    compose_file="$service_dir/docker-compose.yml"

    log "Deploying: $service"
    docker compose -f "$compose_file" up -d

    log "Validating: $service"
    docker compose -f "$compose_file" ps
done
```

**Step 3: Deploy via Single Command**
```bash
ssh -p 22022 admin@10.10.10.100 "sudo bash /mnt/lxc102scripts/ugreen-phase3-deploy-services.sh"
```

---

## ✅ Key Findings from Codebase Audit

1. **No Portainer API integration** - Only web UI setup documented
2. **Partial docker-compose usage** - NPM has it, others don't
3. **Strong CLI patterns** - Phase 1b/1c scripts use docker run effectively
4. **Docker networks ready** - 3 isolated networks already created (frontend/backend/monitoring)
5. **Automation framework exists** - Can build Phase 3 following Phase 1b/1c patterns

---

## 📝 Documentation Files Referenced

| File | Status | Purpose |
|------|--------|---------|
| SESSION-123-VM100-HARDENING-COMPLETE.md | ✅ | Phase 1c completion |
| SESSION-99B-NFS-SUCCESS-AND-PHASE1B-PARTIAL.md | ✅ | Phase 1b Docker setup |
| SESSION-94-COMPLETE-AUTOMATION-WITH-HARDENING.md | ✅ | Automation framework |
| `/home/sleszugreen/scripts/vm100ugreen/hardening/` | ✅ | Hardening scripts (Phase 1c) |
| `/home/sleszugreen/scripts/ugreen-automation/` | ✅ | Automation orchestration |
| DOCKER-SETUP-DECISION-24DEC2025.md | ✅ | Docker architecture |
| SESSION-109-NPM-MIGRATION-COMPLETE.md | ✅ | NPM docker-compose reference |

---

## 🎓 Technical Decisions Made This Session

1. **Recommend Docker Compose over Portainer API**
   - Simpler to implement and maintain
   - Version control friendly
   - Already partially in use (NPM)
   - Matches existing script patterns

2. **Suggest Phase 3 Orchestrator Script**
   - Consistent with Phase 1b/1c automation
   - Single command deployment of all services
   - Automated validation and error handling
   - Session-based documentation

3. **Directory Structure: `/mnt/lxc102scripts/services/`**
   - Centralized service configurations
   - Accessible from both LXC102 and Proxmox host
   - Scales to 15+ services easily
   - Supports .env file management

4. **Do NOT use Portainer web UI for automation**
   - Keep Portainer as monitoring/dashboard tool only
   - Reserve CLI for infrastructure-as-code approach
   - Enables GitOps workflows (future)

---

## ⏭️ Next Steps (When User Decides)

### **Immediate Actions (Ready Now)**
- [ ] Approve Phase 3 service docker-compose file creation
- [ ] Decide on service deployment order (prioritize Nginx PM dependencies)
- [ ] Configure secrets management (.env files)

### **Phase 3a: Service Configuration**
- [ ] Create docker-compose.yml for each of 10 infrastructure services
- [ ] Create docker-compose.yml for each of 7 media services
- [ ] Validate compose syntax (`docker-compose config`)
- [ ] Document service-specific environment variables

### **Phase 3b: Automation**
- [ ] Build ugreen-phase3-deploy-services.sh orchestrator
- [ ] Implement health checks and validation
- [ ] Create rollback procedures
- [ ] Log deployment results

### **Phase 3c: Testing & Deployment**
- [ ] Dry-run on test VM (if available)
- [ ] Deploy to VM100 with validation
- [ ] Configure Nginx PM reverse proxy entries
- [ ] Document access URLs and credentials

---

## 📊 Session Summary

| Item | Status | Details |
|------|--------|---------|
| **Services Identified** | ✅ | 10 infrastructure + 7 media (17 total) |
| **Deployment Methods Analyzed** | ✅ | API, docker-compose, docker CLI |
| **Current Infrastructure** | ✅ | Portainer + Docker + NPM confirmed |
| **Recommended Approach** | ✅ | Docker Compose + orchestrator script |
| **Implementation Ready** | ✅ | Framework exists, services need config |
| **Phase 3 Planning** | ✅ | Directory structure and strategy defined |

---

**Generated:** 14 January 2026 @ 16:45 CET
**Token Usage:** 57,200 / 200,000 budget (28.6% weekly)
**Next Session:** Phase 3 service docker-compose creation (awaiting user approval)

