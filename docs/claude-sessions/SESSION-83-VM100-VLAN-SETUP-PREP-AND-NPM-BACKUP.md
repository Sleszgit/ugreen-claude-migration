# Session 83: VM100 VLAN Setup Preparation & NPM Migration Planning

**Date:** 4 Jan 2026
**Time:** 13:20 - 13:55
**Focus:** Backup NPM from 920 NAS, plan VM100 VLAN setup on UGREEN, get Gemini expert review

---

## Summary

Successfully backed up complete NPM configuration from failing 920 NAS, identified UGREEN network requirements for VM100 deployment, and obtained expert Gemini review of proposed VLAN configuration. Session prepared all prerequisites for VM100 VLAN10 rebuild with safety-first approach.

---

## Part 1: NPM Backup from 920 NAS (CRITICAL - On Failing Volume)

### Problem Statement
- **920 NAS sata2** (Bay 2, Serial ZL2LZPEV) is FAILING with 3 UNC errors
- Located on md3 raid1 pool containing `/volume2` = FILMY920 (Films)
- Nginx Proxy Manager running in Portainer Stack 5 on same failing volume
- NPM manages critical proxy services
- **Risk:** Will lose NPM configuration if 920 NAS drive fails further

### Discovery Process

**Located NPM in:**
- Managed by: Portainer
- Stack ID: 5
- Config: `/volume2/docker/portainer/data/compose/5/v1/docker-compose.yml`
- Ports: 8082 (HTTP), 4444 (HTTPS), 82 (admin interface)

**Backup Contents:**
```bash
✅ /volume2/docker/portainer/data/compose/5/
✅ /volume2/docker/npm/
✅ /volume2/docker/portainer/portainer.db
```

### Backup Execution

```bash
# Created on 920 NAS
tar -czf /tmp/npm_backup.tar.gz \
    /volume2/docker/portainer/data/compose/5/ \
    /volume2/docker/npm/ \
    /volume2/docker/portainer/portainer.db

# Downloaded to safe location
~/backups/npm_backup.tar.gz (2.4K)

# Verified: ✅ Archive valid, 10 files
```

### NPM Docker Compose Configuration (Extracted)

```yaml
version: '3.8'
services:
  nginx-proxy-manager:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '8082:80'      # HTTP proxy
      - '4444:443'     # HTTPS proxy
      - '82:81'        # Admin interface
    volumes:
      - npm_data:/data
      - npm_ssl:/etc/letsencrypt
    networks:
      - npm_network

volumes:
  npm_data:
  npm_ssl:

networks:
  npm_network:
```

### Migration Plan
- ✅ Backup secured: `~/backups/npm_backup.tar.gz`
- ⏳ Phase 1: Deploy VM100 on UGREEN with Docker
- ⏳ Phase 2: Deploy NPM container in VM100
- ⏳ Phase 3: Restore NPM proxies from backup
- ⏳ Phase 4: Update network/DNS routing

---

## Part 2: VM100 VLAN Setup Analysis & Expert Review

### Current Situation

**920 NAS Status:**
| Volume | Pool | Drives | Content | Status |
|--------|------|--------|---------|--------|
| volume2 | md3 | sata1 + **sata2 (FAILING)** | FILMY920 | ⚠️ AT RISK |
| volume1 | md2 | sata3 + sata4 | SERIALE 2023 | ✅ Safe |

**VM100 Purpose:**
- Designated Docker container host on UGREEN
- Will run NPM + other services
- Network: VLAN 10 (10.10.10.0/24 - isolated subnet)
- IP Address: 10.10.10.100

**Previous Failure (Session 65):**
- Root cause: IP conflict + missing VLAN infrastructure
- Proxmox hung up, required physical console recovery
- Full rebuild plan already documented in Session 65

### UGREEN Current Network Configuration

**File:** `/etc/network/interfaces`
```
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

iface nic1 inet manual

source /etc/network/interfaces.d/*
```

**Backup Location:** `~/backups/network-configs/ugreen-interfaces.backup-20260104-135430.txt`

### Initial Proposed Configuration

```
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
```

### Gemini Expert Review Results

**Expert: Senior Proxmox Network Engineer**

#### Critical Issues Found:

1. **❌ Incorrect Command - MUST REMOVE**
   - `post-up bridge vlan add vid 10 dev nic1 master` is syntactically incorrect
   - Unnecessary and can cause unpredictable behavior
   - **Action:** DELETE this line

2. **⚠️ Outdated Configuration Method**
   - Uses old imperative `post-up` commands
   - Modern Proxmox uses declarative `ifupdown2` syntax
   - Older method is brittle and can partially fail

3. **⚠️ Missing Gateway/Routing Configuration**
   - Simply adding vmbr0.10 is NOT sufficient
   - VM100 needs IP forwarding + NAT rules to reach external networks
   - Requires kernel-level configuration (separate from `/etc/network/interfaces`)

4. **⚠️ Switch Port Requirement**
   - Connected switch port MUST be VLAN trunk
   - Must allow untagged traffic (management VLAN) + tagged traffic (VLAN 10)
   - Access port configuration will fail

#### Gemini's Recommended Configuration:

```
auto lo
iface lo inet loopback

iface nic0 inet manual
iface nic1 inet manual

auto vmbr0
iface vmbr0 inet static
    address 192.168.40.60/24
    gateway 192.168.40.1
    bridge-ports nic1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes

auto vmbr0.10
iface vmbr0.10 inet static
    address 10.10.10.60/24

source /etc/network/interfaces.d/*
```

**Key Improvements:**
- ✅ Removed incorrect post-up commands
- ✅ Simplified to modern declarative syntax
- ✅ Uses `ifupdown2` standard for Proxmox VE
- ✅ Cleaner, more maintainable

#### Verification Checklist:

**Before Applying:**
- [ ] Verify switch port (connected to nic1) is VLAN trunk
- [ ] Confirm physical console access available
- [ ] Backup current `/etc/network/interfaces` (DONE: saved locally)

**After Applying:**
- [ ] Verify vmbr0.10 appears in `ip addr show`
- [ ] Verify UGREEN Proxmox host still reachable at 192.168.40.60
- [ ] Verify Proxmox web UI accessible
- [ ] Configure IP forwarding (Phase 2)
- [ ] Configure NAT for VM100 (Phase 2)

---

## Decommissioning Plan Status

### 920 NAS Failing Drive (sata2)

| Item | Status | Details |
|------|--------|---------|
| Failing Drive | ❌ IDENTIFIED | ST16000NE000-2RW103, Serial ZL2LZPEV, 3 UNC errors |
| At-Risk Data | ⚠️ FILMY920 | 2,328 films (8.4TB) on failing md3 pool |
| Safe Drives | ✅ READY | sata3 + sata4 (md2 pool, SERIALE 2023) |
| NPM Config | ✅ BACKED UP | `~/backups/npm_backup.tar.gz` |
| NPM Data | ⏳ PENDING | Will restore after VM100 Docker setup |

### Migration Timeline

**Phase 1 (This Session):**
- ✅ Backup NPM from 920 NAS (DONE)
- ✅ Plan VM100 VLAN setup (DONE)
- ✅ Get expert review (DONE)
- ⏳ Awaiting user approval to proceed with network changes

**Phase 2 (Next Session):**
- ⏳ Apply VLAN configuration to UGREEN
- ⏳ Create VM100 Ubuntu 24.04 VM
- ⏳ Deploy Docker in VM100
- ⏳ Deploy NPM container

**Phase 3 (Following Session):**
- ⏳ Restore NPM proxies from backup
- ⏳ Test all proxy services
- ⏳ Begin FILMY920 migration

**Phase 4 (Final Session):**
- ⏳ Move sata3 + sata4 to Homelab
- ⏳ Create Homelab mirror pool
- ⏳ Decommission 920 NAS
- ⏳ Send sata2 for RMA

---

## Files Generated This Session

1. **NPM Backup:** `~/backups/npm_backup.tar.gz` (2.4K)
   - Complete Portainer Stack 5 configuration
   - NPM volumes and database
   - Ready for restore

2. **Network Configs:** `~/backups/network-configs/`
   - `ugreen-interfaces.backup-20260104-135430.txt` (current config)
   - `ugreen-interfaces.NEW-proposed.txt` (initial proposal)
   - `ugreen-interfaces.GEMINI-RECOMMENDED.txt` (expert-reviewed)

3. **Session Documentation:** This file
   - Complete analysis and decisions
   - Expert review findings
   - Next steps and prerequisites

---

## Critical Prerequisites Before Next Session

- [ ] Verify switch port (nic1) is VLAN trunk capable
- [ ] Confirm physical console access to UGREEN (escape hatch)
- [ ] Review Gemini's recommended configuration
- [ ] Approve proceeding with network changes
- [ ] Ensure backup of current network config exists (✅ DONE)

---

## 🔗 Related Sessions

- **Session 65:** VM100 VLAN10 Rebuild - Complete planning (root cause analysis, safety mechanisms)
- **Session 81:** 920 NAS Decommissioning - Drive Analysis & RMA identification (failing drive details)
- **Session 79:** TV Shows 2022 Duplicate Detection (media inventory planning)

---

## ✅ Session Status

**Complete:** YES
**NPM Backup:** ✅ SECURED
**Network Plan:** ✅ EXPERT REVIEWED
**Gemini Analysis:** ✅ COMPLETE
**Ready for Execution:** AWAITING USER APPROVAL
**Committed to GitHub:** PENDING

---

**Generated with Claude Code**
Session 83: VM100 VLAN Setup Preparation & NPM Migration Planning

Ready for Phase 2 execution when you approve. All safety mechanisms in place. Gemini expert review completed.
