# Docker Setup Decision Session - 24 December 2025

**Location:** LXC 102 (ugreen-ai-terminal), UGREEN Proxmox 192.168.40.60
**Topic:** Docker installation strategy comparison and homelab configuration review
**Outcome:** Decided to use VM approach for UGREEN, replicate homelab setup with improvements

---

## Session Summary

Investigated Docker installation options for UGREEN production infrastructure and examined existing homelab Docker setup to understand best practices and replication strategy.

---

## Key Decision: VM Installation (Not Host or LXC)

### Why NOT Proxmox Host Installation ❌

**Problem:** Docker on Proxmox host = critical infrastructure at risk

- **Security:** Compromised container can escape to host kernel (shared kernel vulnerability)
- **Stability:** Docker issues affect Proxmox container/VM management
- **Rollback:** Difficult to recover from Docker-related host issues
- **Best Practice:** Proxmox design recommends keeping host minimal

### Why NOT LXC Container ⚠️

**Problem:** LXC containers share Proxmox kernel = single point of failure

Attack chain with LXC:
```
Vulnerable container (any app)
  ↓ (Container escape)
Shared Proxmox kernel
  ↓ (Kernel exploit)
Host access → Storage compromise → Full infrastructure at risk
```

**Risk:** Third-party containers (Portainer, community images) are unpredictable

### Why VM Approach ✅ (RECOMMENDED)

**Solution:** Separate kernel = contained failure domain

Attack chain with VM:
```
Vulnerable container (any app)
  ↓ (Container escape)
VM kernel (separate)
  ↓ (BLOCKED at KVM hypervisor boundary)
Can't reach Proxmox or storage
Maximum damage: VM-only compromise
```

**Benefits:**
- Multiple escape barriers: Docker → VM kernel → KVM hypervisor
- Contained failure scope
- Production-grade isolation
- 64GB RAM on UGREEN makes 3GB VM overhead acceptable (5% cost)

---

## Homelab Docker Setup Analysis

**Location:** Homelab Proxmox (192.168.40.40)
**Homelab VM 100:** `docker-services` (32GB RAM, 120GB disk)

### Current Configuration

| Component | Details |
|-----------|---------|
| **Docker version** | 29.1.3 |
| **Containers running** | 3 active |
| **Storage driver** | overlay2 |
| **Daemon config** | Default (no custom daemon.json) |
| **Docker Compose** | NOT installed |
| **Container management** | Manual via docker run commands |
| **Autostart** | Enabled via systemd |
| **Memory usage** | ~37.9MB (minimal overhead) |

### Running Containers

1. **Portainer Agent** (port 9001)
   - Lightweight container management agent
   - Status: Running

2. **Kavita** (port 5000)
   - Comic reader application
   - Status: Running (healthy)

3. **Audiobookshelf** (port 13378)
   - Audiobook management
   - Status: Running

### Architecture

```
Homelab Proxmox (pve, 192.168.40.40)
├─ LXC 101: immich (media server)
├─ LXC 102: ai-terminal (Claude Code)
├─ LXC 200: netbox (network management)
└─ VM 100: docker-services ← Docker here
    ├─ 32GB RAM
    ├─ 120GB disk
    └─ Runs: Portainer Agent, Kavita, Audiobookshelf
```

---

## Homelab Setup: What's Good & What Needs Improvement

### Strengths ✅

- **Current Docker version** (29.1.3) - stable, recent
- **overlay2 storage driver** - efficient, production-ready
- **systemd autostart** - containers restart on VM reboot
- **Portainer Agent** - lightweight remote management
- **Clear port mapping** - web UIs accessible

### Recommendations for UGREEN 🔧

| Issue | Impact | Solution |
|-------|--------|----------|
| **No restart policies** | Container dies → stays dead | Add `--restart=unless-stopped` |
| **No health checks** | Can't auto-recover failed containers | Enable health checks |
| **No resource limits** | Container could consume all VM resources | Set memory/CPU limits |
| **Manual container management** | Hard to recreate setup if needed | Keep docker-compose.yml as documentation |
| **Ports open to 0.0.0.0** | Security risk on network | Restrict to internal IPs only |
| **No backup strategy** | Data loss if container fails | Document volume backup approach |
| **Logging not configured** | Logs could grow indefinitely | Configure log rotation |

---

## UGREEN Docker VM Setup Plan

### Architecture for UGREEN

```
UGREEN Proxmox (192.168.40.60, 64GB RAM)
├─ LXC 102: ugreen-ai-terminal (Claude Code)
│   └─ Connects to Docker VM over network
│
└─ VM (NEW): docker-services
    ├─ OS: Ubuntu 24.04 LTS
    ├─ CPU: 4 vCPU
    ├─ RAM: 8GB (leaves 56GB for other services)
    ├─ Disk: 50GB
    ├─ Docker 29.1.3
    ├─ Portainer CE Server (full management UI)
    ├─ Portainer Agent (for remote monitoring)
    └─ Container management via Portainer Web UI
```

### Key Requirements for UGREEN Setup

**Container Management:**
- ✅ Use **Portainer CE Server** (web UI for management)
- ✅ Manage containers via Portainer (visual UI)
- ✅ Avoid manual CLI management where possible

**Production Safeguards:**
- ✅ Restart policies: `--restart=unless-stopped`
- ✅ Health checks enabled per container
- ✅ Resource limits (CPU/Memory per container)
- ✅ Named volumes (not bind mounts) for data persistence
- ✅ Internal network isolation (custom Docker network)
- ✅ Firewall: ports restricted to internal IPs only
- ✅ Logging: configured log rotation

**Documentation & Recovery:**
- ✅ docker-compose.yml (for disaster recovery)
- ✅ Backup strategy for volumes
- ✅ Container inventory documentation

---

## Comparison: Homelab vs UGREEN

| Aspect | Homelab | UGREEN (Planned) |
|--------|---------|-----------------|
| **Docker version** | 29.1.3 | 29.1.3 |
| **VM RAM** | 32GB | 8GB |
| **Storage driver** | overlay2 | overlay2 |
| **Container management** | Manual + Portainer Agent | Portainer CE Server (full UI) |
| **Restart policies** | Manual setting needed | Set in Portainer |
| **Health checks** | Only Audiobookshelf has | All containers configured |
| **Resource limits** | None currently | Set per container |
| **Volumes** | Likely bind mounts | Named volumes |
| **Firewall** | Open to 0.0.0.0 | Restricted to internal IPs |
| **Backup strategy** | Not documented | To be documented |
| **Log rotation** | Not configured | Configured |

---

## Implementation Next Steps

1. **Create Docker VM on UGREEN** (VM ~104)
   - 8GB RAM, 4vCPU, 50GB disk
   - Ubuntu 24.04 LTS
   - Autostart enabled

2. **Install Docker** (29.1.3)
   - Official Docker repository method
   - Standard configuration

3. **Deploy Portainer CE Server**
   - Web UI for container management
   - Administrative interface for UGREEN

4. **Configure networking**
   - LXC 102 ↔ Docker VM network access
   - Firewall rules for ports

5. **Document setup**
   - docker-compose.yml with all containers
   - Backup procedures
   - Recovery runbook

6. **Migrate/recreate containers**
   - Replicate homelab services (if needed)
   - Add new services via Portainer

---

## Security Considerations for Production

### Why VM is Appropriate for Production

- **Isolation:** Separate kernel prevents host compromise
- **Containment:** Attack chains have 3-4 barriers (Docker → VM kernel → KVM → Proxmox)
- **Failure scope:** Compromised container ≠ compromised infrastructure
- **UGREEN context:** Production storage (20TB) and other services protected

### Firewall Rules to Implement

```
# Only allow internal network to container ports
IN ACCEPT -source 192.168.40.0/24 -p tcp -dport 9001 (Portainer)
IN ACCEPT -source 192.168.40.0/24 -p tcp -dport 5000 (Kavita if used)
IN ACCEPT -source 192.168.40.0/24 -p tcp -dport 13378 (Audiobookshelf if used)

# Block external access
IN DROP -p tcp -dport 9001,5000,13378 (default deny)
```

---

## Notes & Observations

**Homelab Design:**
- Simple, functional setup without over-engineering
- Suitable for homelab (development/testing)
- Lacks production safeguards

**UGREEN Requirements:**
- Production environment with critical storage
- Requires isolation, monitoring, and recovery procedures
- Portainer CE gives visual management without CLI complexity
- 3GB VM overhead justified for infrastructure protection

**Resource Allocation (UGREEN 64GB):**
- VM 100: 8GB (Docker containers)
- LXC 102: 4GB (Claude Code) - can increase if needed
- Remaining: 52GB available for other services/future growth
- Hypervisor: ~4GB base + cache

---

## Session Metadata

**Date:** 24 December 2025
**Duration:** ~45 minutes
**Commands executed:**
- Docker version checks (homelab and UGREEN)
- Container listing (`docker ps -a`)
- Docker daemon status verification
- System information checks

**Files reviewed:**
- ~/.claude/CLAUDE.md (infrastructure config)
- Homelab Docker daemon config
- Homelab systemd docker.service status

**Decision made:** ✅ Use VM approach for UGREEN Docker
**Next phase:** Implementation planning for Docker VM creation

---

## References

- Proxmox VE Documentation: https://pve.proxmox.com/
- Docker Official Installation: https://docs.docker.com/install/
- Portainer CE: https://www.portainer.io/
- Previous session: Docker Installation - Summary (Session 23 Dec 2025)
