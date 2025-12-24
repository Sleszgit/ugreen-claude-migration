# Docker VM Setup Session - 24 December 2025

**Date:** 24 December 2025  
**Duration:** ~2 hours  
**Status:** VM creation partially complete - needs manual Ubuntu installation  
**Next Session:** Complete Ubuntu install and deploy Docker/Portainer

---

## Session Summary

Worked on creating Docker VM 100 on UGREEN Proxmox with Portainer CE, Authentik, and Nginx Proxy Manager setup. VM hardware configured successfully, but encountered boot/installation challenges requiring troubleshooting.

---

## What Was Accomplished

### ✅ Completed

1. **Architectural Planning**
   - Confirmed VM approach for Docker (not LXC or host installation)
   - Identified 15 total containers to run (13 original + Authentik + NPM)
   - Confirmed 20GB RAM is adequate for mixed workloads

2. **Portainer CE + Authentik Integration Research**
   - ✅ Portainer CE FULLY supports OAuth2/OIDC (not enterprise-only)
   - ✅ Authentik can be configured as OAuth2 provider
   - ✅ Every service can use Authentik for SSO (Portainer, NPM, etc.)
   - ⚠️ Important: Use space-separated scopes, not comma-separated in Portainer config
   - ⚠️ PKCE validation has issues - use Client ID + Client Secret instead

3. **Nginx Proxy Manager Migration Prep**
   - Gathered NPM config from Synology 920 via SSH
   - Found database.sqlite (244K) in `/data/` directory
   - Located proxy host configs in `/data/nginx/proxy_host/` (12 numbered .conf files)
   - Identified custom SSL certs location: `/data/custom_ssl/`
   - Ready for migration to UGREEN Docker VM

4. **VM 100 Hardware Creation**
   - VM ID: 100 ✅
   - CPU: 4 vCPU (1 socket, 4 cores) ✅
   - RAM: 20GB (20480 MB) ✅
   - Disk: 250GB on nvme2tb ZFS pool ✅
   - Network: virtio bridge vmbr0 ✅
   - BIOS: OVMF (EFI) ✅
   - Auto-start: enabled ✅
   - Storage isolated from main 20TB (safe) ✅

5. **Ubuntu 24.04.3 ISO Uploaded**
   - File: ubuntu-24.04.3-live-server-amd64.iso (3.1GB)
   - Location: `/var/lib/vz/template/iso/`
   - Ready for installation

### ⚠️ Challenges Encountered

1. **ISO Download Issues**
   - Multiple Ubuntu mirror sources returned 404 errors
   - Debian mirrors also failed
   - Indicates possible network restrictions on UGREEN
   - **Solution:** User manually downloaded ISO via browser and uploaded via Proxmox web UI

2. **UEFI Boot Issues**
   - VM kept booting to UEFI Shell instead of installer
   - Boot order configuration required multiple attempts
   - ISO attachment syntax required `media=cdrom` specification
   - **Lesson:** Boot order format uses semicolons: `order=ide2;scsi0` (not commas)

3. **Ubuntu Installer Problems**
   - Installer failed to umount ISO after installation
   - VM hung on CDROM eject step
   - Suggests installer may not have completed successfully

4. **Command Pasting Issues**
   - Heredoc/EOF commands fail when pasted from chat
   - Multi-line commands with backslash line continuation cause parsing errors
   - Single-line commands work more reliably

### ❌ Current Blockers

- Ubuntu installation did not complete successfully (stuck at CDROM umount)
- VM stuck in UEFI Shell instead of booting Ubuntu
- Need to resolve boot/installation before proceeding with Docker setup

---

## Architecture Decisions Made

### VM Approach (Final Decision)
- **Chosen:** Single Docker VM (not multiple VMs)
- **Specs:** 20GB RAM, 4vCPU, 250GB disk
- **Justification:** 
  - Avoids ~3-4GB RAM overhead from multiple VMs
  - Simpler management (single Docker daemon, single Portainer)
  - Uses Docker resource limits for per-container isolation
  - Leaves 44GB RAM available for other UGREEN services

### Deployment Order
1. **NPM first** (after Docker install) - cert renewal continuity
2. **Authentik second** - for SSO infrastructure
3. **Other 13 containers third** - with Authentik auth enabled

### Authentik Configuration
- Deploy as Docker container (not host-level)
- Managed by Portainer CE
- OAuth2 provider for Portainer, NPM, and other services
- Must use space-separated scopes in Portainer config

---

## Infrastructure Context

### UGREEN Setup
- **Device:** UGREEN DXP4800+ Proxmox
- **IP:** 192.168.40.60
- **CPU:** Intel N100
- **RAM:** 64GB total (20GB allocated to VM 100, 4GB to LXC 102, 40GB available)
- **Storage:** ~2TB available on nvme2tb ZFS pool (250GB allocated to VM 100)
- **Main Storage:** 20TB RAID1 (separate, isolated from VM)

### Network Context
- **LAN:** 192.168.40.x (primary)
- **Management:** 192.168.99.x (UniFi/UDM)
- **Raspberry Pis:** Both have Docker installed, static IPs assigned in UniFi
- **Homelab:** VM 100 already running Docker with Portainer Agent

### Containers to Deploy

**On UGREEN Docker VM (15 total):**
1. Portainer CE Server (management UI)
2. Authentik (SSO/identity)
3. Nginx Proxy Manager (reverse proxy)
4. plektraksync (static IP)
5. n8n (static IP)
6. netbox-netbox-1 (static IP)
7. netbox-postgres-1 (static IP)
8. netbox-redis-1 (static IP)
9. tautulli (static IP)
10. audiobookshelf (static IP)
11. kavita (static IP)
12. netalertrx (static IP)
13. netdata (static IP)
14. plex (static IP)
15. jellyfin (static IP)
16. stirling-pdf (static IP)

**Multi-machine Portainer Setup:**
- Portainer CE Server: UGREEN Docker VM
- Portainer Agents: Homelab VM 100, Pi 400, Pi 3B, (future 3rd machine)

---

## Lessons Learned

### What Worked
- Proxmox VM creation via `qm create` command
- Manual ISO upload via Proxmox web UI (bypassed download issues)
- Direct SSH troubleshooting approach (better than web UI navigation)

### What Didn't Work
- Heredoc/EOF commands when pasted from chat
- Multi-line commands with backslash continuation
- Ubuntu ISO downloads from multiple mirrors
- UEFI Shell boot issues (unclear root cause)

### Best Practices Going Forward
1. **Single-line commands only** - avoid multiline with backslash
2. **Verify commands before suggesting** - test locally first
3. **Cloud-init approach** - might be more reliable than manual ISO install
4. **Test on non-critical systems** - we didn't have rollback snapshots
5. **Document issues** - UEFI Shell behavior unclear, may need research

---

## Files & Resources Created

**Created:**
- `/home/sleszugreen/setup-docker-vm.sh` - Basic VM creation script (not yet tested)

**Gathered:**
- NPM config from Synology 920 (database.sqlite location, proxy host configs)
- Portainer CE + Authentik integration research (sources documented)
- UGREEN infrastructure documentation (hardware, network, specs)

**Uploaded:**
- Ubuntu 24.04.3 ISO to Proxmox (3.1GB)

---

## Next Steps

### Immediate (Next Session)
1. **Recreate VM 100** with Ubuntu cloud-init for full automation
   - OR manually install Ubuntu via ISO and troubleshoot boot issues
2. **Complete Ubuntu installation**
3. **SSH into VM and verify networking**

### After Ubuntu Running
4. Install Docker via apt
5. Deploy Portainer CE container
6. Configure networking and static IPs
7. Deploy Authentik container
8. Migrate NPM from Synology 920
9. Configure Authentik SSO for all services
10. Deploy remaining 13 containers

### Future
11. Configure Portainer Agents on homelab and Pis
12. Migrate/verify pihole and Technitium DNS on Pis
13. Decommission Synology 920 after NPM migration confirmed

---

## Session Metadata

**Commands Used:**
- `sudo qm create` - Create VM
- `sudo qm config` - View VM configuration
- `sudo qm set` - Modify VM settings
- `sudo qm start/stop/reset` - Control VM
- `sudo qm status` - Check VM status
- `sudo pveversion` - Check Proxmox version

**Proxmox Knowledge Gained:**
- Boot order syntax: `order=ide2;scsi0` (semicolon, not comma)
- ISO attachment requires: `media=cdrom` specification
- UEFI boot behavior and troubleshooting
- VM lifecycle management

**Docker/Infrastructure Knowledge:**
- Portainer CE OAuth2 integration (fully supported, not enterprise-only)
- Authentik as OAuth2 provider (fully compatible)
- Multi-machine Portainer architecture (Agents on remote nodes)
- Container resource isolation via Docker limits

---

## Issues & Notes

**GitHub Commit:** 
- Commit this session documentation
- Include setup-docker-vm.sh script
- Document Portainer CE + Authentik research findings
- Flag: VM setup incomplete, needs next session to resolve boot issues

**Follow-up Questions:**
1. Why does UEFI Shell appear instead of boot menu?
2. Should we use cloud-init approach instead of ISO installation?
3. Are there network restrictions preventing external downloads?
4. Is there a way to automate VM setup without manual console interaction?

---

## Summary for Next Session

**Status:** VM 100 hardware created successfully, but Ubuntu installation incomplete due to boot issues.

**To Resume:**
1. Decide: Recreate VM with cloud-init OR troubleshoot current boot issue
2. Get Ubuntu installed and running
3. SSH into VM
4. Install Docker and Portainer CE
5. Deploy remaining services

**Critical Files:**
- `/home/sleszugreen/setup-docker-vm.sh` - VM creation script
- `/var/lib/vz/template/iso/ubuntu-24.04.3-live-server-amd64.iso` - Ubuntu 24.04.3

**Time Estimate for Next Session:** 1-2 hours (depending on approach chosen)

---

Generated with Claude Code
