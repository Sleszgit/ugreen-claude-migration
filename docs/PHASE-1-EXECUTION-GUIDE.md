# Phase 1: VM100 Creation, Docker, and Hardening - Complete Execution Guide

**Date:** 6 January 2026
**Status:** Ready for Execution
**Duration:** ~3-4 hours total (depends on Ubuntu installation speed)

---

## Overview

**Phase 1** builds upon the completed Phase 0 VLAN10 infrastructure and creates a production-ready VM100 (ugreen-infra) with Docker and comprehensive security hardening.

### What Phase 1 Does

| Stage | Script | Purpose | Duration |
|-------|--------|---------|----------|
| **1a** | `ugreen-phase1-vm100-create.sh` | Create VM100 on VLAN10, attach Ubuntu ISO | ~5 min |
| **1b** | `ugreen-phase1-vm100-docker.sh` | Install Docker, Docker Compose, Portainer CE | ~10 min |
| **1c** | `ugreen-phase1c-vm100-hardening-orchestrator.sh` | Run production hardening (SSH, firewall, Docker security) | ~90 min |

---

## Prerequisites

### Before Starting Phase 1

✅ **Phase 0 Status:** VLAN10 fully operational
✅ **VLAN10 Networking:** Host gateway at 10.10.10.60, bridge-vlan-aware enabled
✅ **Ubuntu ISO:** Must be available on Proxmox host
✅ **Console Access:** Proxmox web UI or direct host access for manual Ubuntu installation

### Ubuntu ISO Check

The script requires: `ubuntu-24.04-live-server-amd64.iso`

**Check if ISO is available:**
```bash
ls -lh /var/lib/vz/template/iso/ubuntu-24.04-live-server-amd64.iso
```

**If NOT present, download it on Proxmox host:**
```bash
cd /var/lib/vz/template/iso/
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
```

---

## Phase 1 Execution Workflow

### Stage 1a: VM100 Creation (5 minutes)

**Execute on Proxmox host (192.168.40.60):**

```bash
sudo bash /nvme2tb/lxc102scripts/ugreen-phase1-vm100-create.sh
```

**What happens:**
1. Validates prerequisites (qm available, VM doesn't exist, storage pool exists)
2. Creates VM100 with:
   - VMID: 100
   - Name: ugreen-infra
   - CPU: 4 cores
   - RAM: 16GB
   - Disk: 100GB (nvme2tb pool)
   - Network: vmbr0 with VLAN tag 10
3. Configures cloud-init for static IP
4. Starts VM with Ubuntu ISO attached
5. Displays next steps

**Expected output:**
```
✓ VM100 created successfully
✓ VM100 is running
===============================================
✓ VM100 Created Successfully!
===============================================
MANUAL STEPS REQUIRED:
1. Open Proxmox console for VM100 (VMID 100)
2. Complete Ubuntu 24.04 installation...
```

**Log location:** `/tmp/vm100-create-TIMESTAMP.log`

---

### Stage 1a Extended: Manual Ubuntu Installation

**Duration:** 15-30 minutes (user interaction required)

**Steps:**
1. Open Proxmox web UI → VMs → VM100 → Console
2. Boot into Ubuntu installer
3. Follow installation steps:
   - **Language:** English
   - **Keyboard:** Select your layout
   - **Network:** Initially DHCP, then:
     - IPv4: `10.10.10.100/24`
     - Gateway: `10.10.10.60`
     - DNS: `192.168.40.50` (Pi-Hole), fallback `8.8.8.8`
   - **Storage:** Use entire disk (LVM optional)
   - **User:** Create admin user (e.g., `admin` / `password`)
   - **SSH:** ✅ Enable OpenSSH server (CRITICAL!)
   - **Updates:** Skip (we'll do this in Phase 1b)
4. Complete installation, reboot
5. VM boots to login prompt with IP configured

**Verify after installation:**
```bash
# From Proxmox host or any machine on VLAN10:
ssh admin@10.10.10.100
# Should connect with password you created
```

---

### Stage 1b: Docker & Portainer Installation (10 minutes)

**Execute on VM100 after Ubuntu installation:**

**Option A: Via SSH from Proxmox host**
```bash
ssh -u admin 10.10.10.100 "sudo bash -s" < /nvme2tb/lxc102scripts/ugreen-phase1-vm100-docker.sh
```

**Option B: SSH directly to VM and run locally**
```bash
ssh admin@10.10.10.100
sudo bash /tmp/ugreen-phase1-vm100-docker.sh
```

**What happens:**
1. Validates root access and Ubuntu OS
2. Creates log directory (`/var/log/`)
3. Sets timezone to Europe/Warsaw
4. Installs Docker CE from official Docker repository
5. Installs Docker Compose (standalone binary)
6. Configures Docker daemon with:
   - JSON logging (10MB max, 3 files rotation)
   - overlay2 storage driver
7. Bootstraps Portainer CE:
   - Creates Docker volume: `portainer_data`
   - Deploys Portainer container on port 9443
   - Waits for Portainer to be ready
8. Runs 5-point verification

**Expected output:**
```
✓ Ubuntu detected: Ubuntu 24.04 LTS
✓ Log directory writable
✓ Docker installed: Docker version 27.x.x
✓ Docker Compose installed: Docker Compose version 2.x.x
✓ Docker daemon configured
✓ Portainer container is running
✓ Portainer is responding
✓ Verification complete: 5/5 checks passed

===============================================
✓ Docker & Portainer Installation Complete!
===============================================
Portainer Access:
  URL: https://10.10.10.100:9443
```

**Log location:** `/var/log/docker-setup-TIMESTAMP.log`

**Next action:** Access Portainer to verify it's working:
```bash
# Open in browser:
https://10.10.10.100:9443
# (Accept self-signed certificate warning)
```

---

### Stage 1c: Production Hardening Orchestrator (90 minutes)

**Execute on VM100 after Docker is running:**

```bash
ssh admin@10.10.10.100
sudo bash /tmp/ugreen-phase1c-vm100-hardening-orchestrator.sh
```

**What Phase A hardening does (6 scripts):**

| Script | Purpose | Changes |
|--------|---------|---------|
| `00-pre-hardening-checks.sh` | Validation and backup | Backups critical configs |
| `01-ssh-hardening.sh` | Secure SSH | Port → 22022, keys-only, rate limiting |
| `02-ufw-firewall.sh` | Host firewall | UFW enabled, default DENY, selective allow |
| `03-docker-daemon-hardening.sh` | Docker security | userns-remap, --icc=false, logging |
| `04-docker-network-security.sh` | Network isolation | Creates 3 isolated networks: frontend, backend, monitoring |
| `05-portainer-deployment.sh` | Portainer relocation | Moves Portainer to monitoring network |
| `05-checkpoint-phase-a.sh` | Verification & report | Generates CHECKPOINT-A-RESULTS.txt |

**Expected progression:**
```
[1/7] Validating prerequisites...
[2/7] Preparing hardening scripts...
[3/7] Verifying script availability...
[4/7] Executing hardening sequence...
  [1/7] Executing: 00-pre-hardening-checks.sh
    ✓ Creating backups...
    ✓ Backups stored in /root/vm100-hardening/backups/
  [2/7] Executing: 01-ssh-hardening.sh
    ✓ SSH port changed to 22022
    ✓ Password auth disabled
    ✓ SSH key verification enabled
  [3/7] Executing: 02-ufw-firewall.sh
    ✓ UFW firewall enabled
    ✓ Default policy: DENY
    ✓ Allowed: SSH (22022), Portainer (9443), Docker API
  [4/7] Executing: 03-docker-daemon-hardening.sh
    ✓ Docker hardening applied
    ✓ userns-remap enabled (dockremap user)
    ✓ Inter-container communication disabled
  [5/7] Executing: 04-docker-network-security.sh
    ✓ Networks created: frontend, backend, monitoring
    ✓ Network policies applied
  [6/7] Executing: 05-portainer-deployment.sh
    ✓ Portainer reconfigured
    ✓ Moved to monitoring network
    ✓ Running on port 9443
  [7/7] Executing: 05-checkpoint-phase-a.sh
    ✓ Checkpoint verification complete
    ✓ Results saved
[5/5] Verifying completion...
✓ Check 1/4: SSH configured on port 22022
✓ Check 2/4: UFW firewall is active
✓ Check 3/4: Docker networks created (found 3)
✓ Check 4/4: Portainer is running
```

**After hardening completes:**

✅ **SSH Access Changed:**
```bash
# OLD (no longer works):
ssh admin@10.10.10.100

# NEW (required after hardening):
ssh -p 22022 admin@10.10.10.100
```

✅ **Portainer Access:**
```
URL: https://10.10.10.100:9443
Status: Running on monitoring network
```

**Log location:** `/var/log/vm100-hardening-TIMESTAMP.log`

**Verification results:** `/root/vm100-hardening/CHECKPOINT-A-RESULTS.txt`

---

## Complete Timeline

| Phase | Duration | Cumulative | Status |
|-------|----------|-----------|--------|
| Phase 1a: VM creation | 5 min | 5 min | Automated |
| **Manual Ubuntu install** | **15-30 min** | **20-35 min** | **Manual** |
| Phase 1b: Docker setup | 10 min | 30-45 min | Automated |
| Phase 1c: Hardening | 90 min | 120-135 min | Automated (long) |
| **Total** | **2-2.5 hours** | **2-2.5 hours** | **Ready for Phase 2** |

---

## Troubleshooting Guide

### Issue: VM100 Creation Fails

**Error:** `qm command not found`
- **Cause:** Script not running as root on Proxmox host
- **Fix:** Use `sudo bash /nvme2tb/lxc102scripts/ugreen-phase1-vm100-create.sh`

**Error:** `VM 100 already exists`
- **Cause:** VM100 was already created in a previous run
- **Fix:** Delete existing VM100, then retry

**Error:** `Storage pool nvme2tb not found`
- **Cause:** Storage pool name mismatch
- **Fix:** Check available pools: `pvesh get /storage` and update script

**Error:** `ISO not found`
- **Cause:** Ubuntu ISO not downloaded to Proxmox host
- **Fix:** Download ISO: `wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso` to `/var/lib/vz/template/iso/`

---

### Issue: Cannot SSH to VM100

**Error:** `Connection refused`
- **Cause:** Ubuntu still installing or SSH not running
- **Fix:** Check console, wait for installation to complete

**Error:** `Connection timeout`
- **Cause:** VM IP not configured correctly
- **Fix:** Check console, verify IP is 10.10.10.100/24

**Error:** `Permission denied (publickey)`
- **Cause:** SSH key auth but keys not set up
- **Fix:** For Phase 1b, use: `ssh admin@10.10.10.100` with password first

---

### Issue: Docker Phase Fails

**Error:** `Failed to install Docker`
- **Cause:** Network issue or repository unreachable
- **Fix:** Check internet connectivity, retry Phase 1b

**Error:** `Docker daemon not responding`
- **Cause:** Docker service didn't start
- **Fix:** SSH to VM, check: `sudo systemctl status docker`

**Error:** `Portainer did not respond in time`
- **Cause:** Normal - Portainer takes time to initialize
- **Fix:** Wait 30 seconds, access: `https://10.10.10.100:9443`

---

### Issue: Hardening Phase Fails

**Error:** `Phase A source not found`
- **Cause:** Hardening scripts not in correct location
- **Fix:** Verify: `ls /home/sleszugreen/scripts/vm100ugreen/hardening/`

**Error:** `SSH port changed to 22022 but can't connect`
- **Cause:** UFW firewall blocking the port
- **Fix:** Use Proxmox console to access VM and review firewall rules: `sudo ufw status`

**Error:** `Scripts missing`
- **Cause:** Copy operation failed
- **Fix:** Manually copy scripts: `cp /home/sleszugreen/scripts/vm100ugreen/hardening/*.sh /opt/hardening/`

---

## After Phase 1 Completes

### Immediate Post-Deployment

1. **Verify all services running:**
   ```bash
   # SSH on new port
   ssh -p 22022 admin@10.10.10.100

   # Check status
   sudo systemctl status docker
   sudo ufw status
   docker ps
   ```

2. **Access Portainer:**
   - URL: `https://10.10.10.100:9443`
   - Create admin user on first access
   - Verify 3 Docker networks exist (frontend, backend, monitoring)

3. **Review hardening results:**
   ```bash
   cat /root/vm100-hardening/CHECKPOINT-A-RESULTS.txt
   ```

4. **Backup critical configs:**
   ```bash
   ls /root/vm100-hardening/backups/
   ```

### Next Steps (Phase 2)

Phase 2 will:
- Create LXC103 media container
- Configure Samba/NFS storage access
- Deploy Portainer Stack with services

---

## Emergency Procedures

### Lost SSH Access After Hardening

**If you can't SSH on port 22022:**

1. Access VM console via Proxmox web UI
2. Login with admin user (password)
3. Run emergency rollback:
   ```bash
   sudo /opt/hardening/99-emergency-rollback.sh
   ```
4. This restores SSH to port 22
5. Contact support with logs from `/var/log/vm100-hardening-*.log`

### Partial Hardening Failure

If Phase 1c fails partway through:

1. Check log: `/var/log/vm100-hardening-TIMESTAMP.log`
2. Note which script failed
3. Fix the issue
4. Restart Phase 1c (it will resume from failure point)

### Full Rollback to Clean State

To start Phase 1 completely over:

```bash
# On Proxmox host
sudo qm stop 100
sudo qm destroy 100

# Then restart Phase 1a
sudo bash /nvme2tb/lxc102scripts/ugreen-phase1-vm100-create.sh
```

---

## Critical Notes

⚠️ **SSH Port Change:** After Phase 1c, SSH moves from port 22 to 22022
⚠️ **Manual Installation:** Ubuntu installation cannot be automated; you must use Proxmox console
⚠️ **Timing:** Total duration ~2-2.5 hours (mostly manual install waiting time)
⚠️ **Network:** Verify 10.10.10.0/24 connectivity before proceeding

---

## Success Checklist

After completing Phase 1, you should have:

- [ ] VM100 created with 4 cores, 16GB RAM, 100GB disk
- [ ] Ubuntu 24.04 LTS installed with static IP 10.10.10.100/24
- [ ] Docker CE and Docker Compose installed and running
- [ ] Portainer CE running on port 9443
- [ ] SSH hardened on port 22022 (keys-only)
- [ ] UFW firewall active with rate limiting
- [ ] 3 Docker networks created (frontend, backend, monitoring)
- [ ] All checkpoint verifications passing
- [ ] Logs saved for audit trail

---

## Quick Reference Commands

```bash
# Check Phase 0 status (VLAN10)
ssh -p 22022 ugreen-host "ip addr show vmbr0.10"

# Check VM100 status on Proxmox
ssh -p 22022 ugreen-host "qm status 100"

# SSH to VM100 after hardening
ssh -p 22022 admin@10.10.10.100

# View Phase 1c results
ssh -p 22022 admin@10.10.10.100 "sudo cat /root/vm100-hardening/CHECKPOINT-A-RESULTS.txt"

# Check Docker status
ssh -p 22022 admin@10.10.10.100 "sudo docker ps"

# Access Portainer
https://10.10.10.100:9443
```

---

**Phase 1 Status:** Ready for Execution
**Created:** 6 January 2026
**Last Updated:** 6 January 2026
