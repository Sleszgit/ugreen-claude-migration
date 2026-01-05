# UGREEN Complete Execution Workflow (with Phase 1c Hardening)

**Updated:** 5 January 2026
**Integration:** Phase 1c production hardening now fully integrated
**Automation Level:** 75% (infrastructure) + 25% (service configuration)

---

## Executive Summary

Complete, production-ready automation for deploying 17 services across UGREEN with **full production hardening included**.

### What's New (Phase 1c)

✅ **Automated hardening orchestrator** - Single script orchestrates 8 Phase A hardening scripts
✅ **Production-ready security** - SSH hardening, UFW firewall, Docker daemon hardening
✅ **Integrated networks** - 3 isolated Docker networks for frontend/backend/monitoring
✅ **Emergency rollback** - Automatic fallback available if hardening issues occur
✅ **Comprehensive logging** - Detailed logs of all hardening operations

---

## Complete Workflow (11 Phases)

### Phase 0: Network Setup (10 min) - AUTOMATED

**Script:** `ugreen-phase0-vlan10-setup.sh`
**Location:** Proxmox host
**Status:** ✅ Ready

Configure VLAN 10 infrastructure with automatic rollback.

```bash
ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase0-vlan10-setup.sh"
```

**Output:**
- ✅ vmbr0.10 interface created at 10.10.10.60/24
- ✅ VLAN awareness enabled
- ✅ All validation checks passed
- ✅ Auto-rollback configured

**Checkpoint:** Verify with `ip addr show vmbr0.10`

---

### Phase 1a: VM100 Creation (5 min) - AUTOMATED

**Script:** `ugreen-phase1-vm100-create.sh`
**Location:** Proxmox host
**Status:** ✅ Ready

Create VM100 with proper specifications.

```bash
ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase1-vm100-create.sh"
```

**Output:**
- ✅ VM 100 created (4 vCPU, 16GB RAM, 100GB disk)
- ✅ VLAN 10 network configured (tag=10)
- ✅ Ubuntu ISO attached
- ✅ VM started and waiting for installation

**Checkpoint:** `qm status 100` should show "running"

---

### Phase 1 Manual: Ubuntu Installation (20-30 min) - MANUAL

**Method:** Proxmox Console
**Status:** ⚠️ Requires user interaction

Complete Ubuntu 24.04 LTS installation via Proxmox console.

**Installation Steps:**
1. Language: English
2. Keyboard: Your layout
3. Network: Static IP configuration
   - IPv4: 10.10.10.100/24
   - Gateway: 10.10.10.60
   - DNS: 192.168.40.50
4. Storage: Use entire disk (LVM optional)
5. User: Create admin user (remember password!)
6. SSH: Enable OpenSSH server ✅
7. Reboot when complete

**Checkpoint:** SSH access should work: `ssh admin@10.10.10.100`

---

### Phase 1b: Docker & Portainer Installation (10 min) - AUTOMATED

**Script:** `ugreen-phase1-vm100-docker.sh`
**Location:** On VM100
**Status:** ✅ Ready

Install Docker and bootstrap Portainer CE.

```bash
# SSH to VM100
ssh admin@10.10.10.100

# Run Docker installation
sudo bash /mnt/lxc102scripts/ugreen-phase1-vm100-docker.sh
```

**Output:**
- ✅ Docker CE installed (latest)
- ✅ Docker Compose installed
- ✅ Timezone: Europe/Warsaw
- ✅ Portainer CE deployed and running
- ✅ All validation checks passed

**Checkpoint:**
- `docker ps` shows Portainer running
- Access: https://10.10.10.100:9443

---

### Phase 1c: Production Hardening (90 min) - AUTOMATED ORCHESTRATION ⭐ NEW

**Script:** `ugreen-phase1c-vm100-hardening-orchestrator.sh`
**Location:** On VM100
**Status:** ✅ Ready
**Orchestrates:** 8 Phase A scripts from Session 36

Apply comprehensive production hardening.

```bash
# Still on VM100
sudo bash /mnt/lxc102scripts/ugreen-phase1c-vm100-hardening-orchestrator.sh
```

**Automated Steps (in sequence):**

1. **00-pre-hardening-checks** (5 min)
   - ✅ Backs up SSH, sysctl, UFW configs
   - ✅ Verifies Docker running
   - ✅ Creates backup directory

2. **01-ssh-hardening** (10 min)
   - ✅ Port changed from 22 → 22022
   - ✅ Password authentication disabled
   - ✅ Root login disabled
   - ✅ Max 3 login attempts
   - ✅ Client keepalive: 300 seconds

3. **02-ufw-firewall** (5 min)
   - ✅ UFW enabled (default deny)
   - ✅ SSH rate limiting enabled
   - ✅ Portainer HTTPS (9443) allowed
   - ✅ Internal-only access (192.168.40.0/24)

4. **03-docker-daemon-hardening** (10 min)
   - ✅ User namespace remapping (container root ≠ host root)
   - ✅ No privilege escalation (no-new-privileges)
   - ✅ Inter-container communication disabled
   - ✅ Log rotation configured (10MB max)
   - ✅ Live restore enabled

5. **04-docker-network-security** (15 min)
   - ✅ Frontend network created (172.18.0.0/16)
   - ✅ Backend network created (172.19.0.0/16)
   - ✅ Monitoring network created (172.20.0.0/16)
   - ✅ No default bridge access
   - ✅ Explicit network connections required

6. **05-portainer-deployment** (10 min)
   - ✅ Portainer re-deployed on monitoring network
   - ✅ Read-only filesystem
   - ✅ No privilege escalation
   - ✅ HTTPS only (self-signed cert)

7. **05-checkpoint-phase-a** (15 min)
   - ✅ 8 comprehensive validation tests
   - ✅ SSH configuration verified
   - ✅ UFW rules verified
   - ✅ Docker daemon settings verified
   - ✅ Network isolation verified
   - ✅ All tests must PASS

8. **99-emergency-rollback** (available)
   - ✅ Accessible if any issues occur
   - ✅ Restores pre-hardening state
   - ✅ Documented in output

**Security Features Summary:**
```
✅ SSH hardened on port 22022
✅ UFW firewall active (rate-limited)
✅ Docker daemon with userns-remap
✅ 3 isolated Docker networks
✅ Portainer in restricted mode
✅ Full backups created
✅ Emergency rollback available
✅ Comprehensive logging
```

**Critical Change:** After this phase, SSH requires key-based auth on port 22022

**Checkpoint:**
- SSH: `ssh -p 22022 -i key admin@10.10.10.100`
- UFW: `sudo ufw status` (should show "active")
- Networks: `docker network ls` (should show 3 custom networks)
- Results: `cat /root/vm100-hardening/CHECKPOINT-A-RESULTS.txt`

**Important:** Keep SSH terminal open during execution as emergency access!

---

### Phase 2a: LXC103 Creation (5 min) - AUTOMATED

**Script:** `ugreen-phase2-lxc103-create.sh`
**Location:** Proxmox host
**Status:** ✅ Ready

Create LXC103 with GPU passthrough for Intel QuickSync.

```bash
ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase2-lxc103-create.sh"
```

**Output:**
- ✅ LXC 103 created (4 cores, 8GB RAM, 50GB disk)
- ✅ VLAN 10 network configured
- ✅ GPU passthrough configured (renderD128)
- ✅ Docker features enabled (nesting)
- ✅ Container started

**Checkpoint:**
- `pct status 103` should show "running"
- `pct exec 103 -- ls -la /dev/dri/` should show renderD128

---

### Phase 2b: Docker on LXC103 (10 min) - AUTOMATED

**Script:** `ugreen-phase2-lxc103-docker.sh`
**Location:** LXC103
**Status:** ✅ Ready

Install Docker and Portainer Agent.

```bash
# From Proxmox:
pct exec 103 -- bash -s < /nvme2tb/lxc102scripts/ugreen-phase2-lxc103-docker.sh
```

**Output:**
- ✅ Docker CE installed
- ✅ Docker Compose installed
- ✅ Timezone: Europe/Warsaw
- ✅ Portainer Agent deployed on port 9001
- ✅ GPU access verified from Docker

**Checkpoint:**
- `pct exec 103 -- docker ps` shows portainer_agent
- GPU: `pct exec 103 -- ls -la /dev/dri/renderD128` accessible

---

### Phase 3: Portainer Configuration (15 min) - MANUAL

**Method:** Portainer Web UI
**Location:** https://10.10.10.100:9443
**Status:** ⚠️ Requires user interaction

Add LXC103 as managed endpoint.

**Steps:**
1. Open Portainer: https://10.10.10.100:9443
2. Create admin user (first time)
3. **Settings** → **Endpoints**
4. **Add environment**
   - Name: `lxc-media`
   - Endpoint: `http://10.10.10.103:9001`
   - Group: Media
5. **Connect**
6. Verify in Endpoints list

**Checkpoint:** Both endpoints show as "Connected"

---

### Phase 4: Storage Mount (5 min) - SEMI-AUTOMATED

**Method:** SSH + Proxmox config
**Status:** ⚠️ Requires manual path confirmation

Mount 20TB SATA array to LXC103.

```bash
# Identify actual storage path:
ssh -p 22022 ugreen-host "mount | grep -E 'storage|media|mnt'"

# Then configure mount in /etc/pve/lxc/103.conf:
mp0: /storage/Media,mp=/mnt/media,ro=0

# Verify:
pct reboot 103
pct exec 103 -- mount | grep mnt/media
```

**Checkpoint:** `/mnt/media` is accessible and writable in LXC103

---

### Phase 5-11: Service Deployment - MANUAL (Portainer UI)

**Method:** Portainer Web UI Stacks
**Duration:** ~2-3 hours (click-based UI deployment)

Deploy 17 services:

#### Infrastructure (VM100) - 10 services
1. Nginx Proxy Manager (routing)
2. Authentik (SSO)
3. Netbird (VPN)
4. Paperless-ngx (documents)
5. SimpleLogin (email)
6. Uptime Kuma (monitoring)
7. Stirling PDF (utilities)
8. Pairdrop (file sharing)
9. Nextexplorer (browser)
10. UniFi Network MCP

#### Media (LXC103) - 7 services
11. Plex (transcoding)
12. Jellyfin (transcoding)
13. Sonarr (TV automation)
14. Radarr (movie automation)
15. Prowlarr (indexer)
16. Bazarr (subtitles)
17. Lidarr (music)

**Checkpoint:** All services deployed and verified in Portainer

---

## Complete Timeline

```
Phase 0: VLAN setup              10 min  ✅ Automated
Phase 1a: VM100 create           5 min   ✅ Automated
Phase 1: Ubuntu install          20-30min ⚠️ Manual
Phase 1b: Docker install         10 min  ✅ Automated
Phase 1c: Hardening (NEW!)       90 min  ✅ Automated orchestration
Phase 2a: LXC103 create          5 min   ✅ Automated
Phase 2b: Docker on LXC          10 min  ✅ Automated
Phase 3: Portainer config        15 min  ⚠️ Manual
Phase 4: Storage mount           5 min   ⚠️ Semi-automated
Phase 5-11: Service deploy       2-3h    ⚠️ Manual (UI clicks)
─────────────────────────────────────
TOTAL INFRASTRUCTURE:            ~4.5-5h
TOTAL WITH SERVICES:             ~6.5-7h
```

---

## Critical Changes in Phase 1c (Hardening)

### SSH Changes
- **Before:** `ssh admin@10.10.10.100`
- **After:** `ssh -p 22022 -i key admin@10.10.10.100`
- **Authentication:** Keys-only (no password)

### Network Changes
- **Firewall:** UFW enabled (blocks external access)
- **Internal access:** 192.168.40.0/24 and 10.10.10.0/24 allowed
- **External:** All blocked unless explicitly allowed

### Docker Changes
- **Isolation:** User namespace remapping enabled
- **Networks:** 3 isolated networks (no default bridge)
- **Privileges:** Containers cannot escalate privileges
- **Communication:** Inter-container communication disabled

---

## Emergency Procedures

### If SSH Access Lost During Hardening
```bash
# Via Proxmox console:
sudo /mnt/lxc102scripts/ugreen-phase1c-vm100-hardening-orchestrator.sh
# Then select option to run rollback script 99
```

### If Hardening Fails Partway
```bash
# Review logs:
cat /var/log/vm100-hardening-*.log

# Check backup configs:
ls -la /root/vm100-hardening/backups/

# Run emergency rollback:
sudo /home/sleszugreen/scripts/vm100ugreen/hardening/99-emergency-rollback.sh
```

### If Firewall Blocks Access
```bash
# Via Proxmox console:
sudo ufw disable
# Then review rules:
sudo ufw show added
# Or restore from backup:
sudo cp /root/vm100-hardening/backups/ufw.backup /etc/ufw/user.rules
sudo ufw reload
```

---

## Success Criteria

### Phase 1c Completion
- ✅ All 8 hardening scripts executed
- ✅ Checkpoint tests: 8/8 PASS
- ✅ SSH accessible on port 22022 with keys
- ✅ UFW active and logging
- ✅ 3 Docker networks created
- ✅ Portainer accessible via HTTPS on monitoring network

### Complete Infrastructure Success
- ✅ All 11 phases completed
- ✅ VLAN10: 10.10.10.0/24 operational
- ✅ VM100: Hardened and production-ready
- ✅ LXC103: GPU passthrough working
- ✅ Portainer: Managing both VM100 and LXC103
- ✅ All 17 services deployed and verified

---

## Key Files Reference

```
/mnt/lxc102scripts/
├── ugreen-phase0-vlan10-setup.sh
├── ugreen-phase1-vm100-create.sh
├── ugreen-phase1-vm100-docker.sh
├── ugreen-phase1c-vm100-hardening-orchestrator.sh ⭐ NEW
├── ugreen-phase2-lxc103-create.sh
├── ugreen-phase2-lxc103-docker.sh
├── UGREEN-AUTOMATION-README.md
├── EXECUTION-WORKFLOW-WITH-HARDENING.md (this file)
└── backups/

/home/sleszugreen/scripts/vm100ugreen/hardening/
├── 00-pre-hardening-checks.sh
├── 01-ssh-hardening.sh
├── 02-ufw-firewall.sh
├── 03-docker-daemon-hardening.sh
├── 04-docker-network-security.sh
├── 05-portainer-deployment.sh
├── 05-checkpoint-phase-a.sh
├── 99-emergency-rollback.sh
└── README-PHASE-A.md
```

---

## Next Steps

1. **Review this workflow** - Understand all phases
2. **Start Phase 0** - VLAN setup (fully automated)
3. **Run Phase 1a** - VM100 creation (fully automated)
4. **Manual Phase 1** - Ubuntu installation (interactive)
5. **Run Phase 1b** - Docker installation (fully automated)
6. **Run Phase 1c** - Hardening (automated orchestration) ⭐
7. **Run Phase 2a** - LXC103 creation (fully automated)
8. **Run Phase 2b** - Docker on LXC (fully automated)
9. **Manual Phase 3** - Portainer endpoint config
10. **Manual Phase 4** - Storage mount verification
11. **Manual Phase 5-11** - Service deployment via UI

---

**Ready to execute?** Start with Phase 0 using the UGREEN-AUTOMATION-README.md guide!

**Status:** ✅ Complete workflow documented and ready for execution
