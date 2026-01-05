# UGREEN Services Automation Scripts

Complete automation for deploying 17 services across UGREEN infrastructure.

**Status:** ~75% automated infrastructure setup, ~25% manual service configuration

**NEW:** Phase 1c VM100 production hardening now fully automated! Integrated orchestration of 8 hardening scripts from Session 36.

---

## Architecture

```
UGREEN Proxmox Host (192.168.40.60)
├── VLAN 10 (10.10.10.0/24)
│
├── VM100 (ugreen-infra) - 10.10.10.100
│   └── 10 Infrastructure Services (via Portainer UI)
│
└── LXC103 (ugreen-media) - 10.10.10.103
    └── 7 Media Services (via Portainer Agent)
```

---

## Automation Workflow

### Prerequisites

- ✅ Proxmox host accessible at 192.168.40.60:22022
- ✅ Ubuntu 24.04 ISO at `/var/lib/vz/template/iso/ubuntu-24.04-live-server-amd64.iso`
- ✅ LXC template: `ubuntu-24.04-standard_24.04-1_amd64.tar.zst` (if not present, can download from Proxmox)
- ✅ Storage pool: `nvme2tb` with at least 150GB free

### Phase 0: Network Setup (~10 min)

**Automated VLAN 10 configuration with safety rollback.**

```bash
# On Proxmox host:
ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase0-vlan10-setup.sh"
```

**What this does:**
- Backs up current network config
- Enables bridge VLAN awareness on vmbr0
- Creates vmbr0.10 interface (10.10.10.60/24)
- Validates 6 connectivity checks
- Auto-rollback if any check fails

**Output:**
- Interface: `vmbr0.10` at `10.10.10.60/24`
- Backup: `/root/network-backups/interfaces.backup-*`
- Log: `/root/network-backups/vlan10-setup-*.log`

---

### Phase 1a: VM100 Creation (~5 min + Ubuntu install)

**Automated VM creation. Ubuntu installation is semi-interactive.**

```bash
# On Proxmox host:
ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase1-vm100-create.sh"
```

**What this does:**
- Creates VM100 (4 vCPU, 16GB RAM, 100GB disk)
- Configures VLAN 10 network (tag=10)
- Attaches Ubuntu ISO
- Starts VM

**Manual Steps (via Proxmox console):**
1. Open Proxmox console → VM 100
2. Complete Ubuntu installation:
   - Network: Static IP `10.10.10.100/24`, gateway `10.10.10.60`
   - Install OpenSSH server
   - Create admin user
3. Reboot when complete

**After Ubuntu boots:**
```bash
ssh admin@10.10.10.100  # Test connectivity
```

---

### Phase 1b: Docker & Portainer on VM100 (~10 min)

**Automated Docker, Docker Compose, and Portainer installation.**

```bash
# Option 1: From Proxmox host
ssh -p 22022 ugreen-host "ssh -u admin 10.10.10.100 'sudo bash -s' < /nvme2tb/lxc102scripts/ugreen-phase1-vm100-docker.sh"

# Option 2: SSH to VM100 directly
ssh admin@10.10.10.100
sudo bash /tmp/ugreen-phase1-vm100-docker.sh
```

**What this does:**
- Installs Docker CE (latest)
- Installs Docker Compose
- Sets timezone to Europe/Warsaw
- Deploys Portainer CE (bootstrap)
- Validates 5 installation checks

**After completion:**
- Portainer at: `https://10.10.10.100:9443`
- Create admin user in Portainer UI
- Ready for hardening

---

### Phase 1c: VM100 Production Hardening (~1.5 hours)

**Automated security hardening suite (8 integrated scripts from Session 36).**

```bash
# On VM100:
ssh admin@10.10.10.100
sudo bash /mnt/lxc102scripts/ugreen-phase1c-vm100-hardening-orchestrator.sh
```

**What this does (Automated orchestration of Phase A):**

1. **00-pre-hardening-checks** - Backup configs, verify Docker
2. **01-ssh-hardening** - Port 22022, keys-only auth, security hardening
3. **02-ufw-firewall** - Enable UFW, rate limiting, internal-only access
4. **03-docker-daemon** - User namespace remapping, no-new-privileges
5. **04-docker-network-security** - 3 isolated networks (frontend/backend/monitoring)
6. **05-portainer-deployment** - Secure Portainer on monitoring network
7. **05-checkpoint-phase-a** - 8-test verification suite
8. **99-emergency-rollback** - Available if rollback needed

**Security Features Applied:**
- ✅ SSH hardened (port 22022, keys-only, limited login attempts)
- ✅ UFW firewall active (blocks external access by default)
- ✅ Docker daemon hardened (user namespace remapping)
- ✅ Docker networks isolated (no inter-container communication by default)
- ✅ Portainer runs in restricted mode
- ✅ Comprehensive logging and backup

**After completion:**
- Checkpoint results: `/root/vm100-hardening/CHECKPOINT-A-RESULTS.txt`
- SSH access: Port 22022 (keys-only, no password)
- Backups: `/root/vm100-hardening/backups/`
- Emergency rollback available if needed

**Important:** After hardening, new SSH connection uses:
```bash
ssh -p 22022 -i /path/to/key admin@10.10.10.100
```

---

### Phase 2a: LXC103 Creation (~5 min)

**Automated LXC creation with GPU passthrough for Intel QuickSync.**

```bash
# On Proxmox host:
ssh -p 22022 ugreen-host "bash /nvme2tb/lxc102scripts/ugreen-phase2-lxc103-create.sh"
```

**What this does:**
- Creates LXC103 (4 cores, 8GB RAM, 50GB disk)
- Configures VLAN 10 network
- Sets up GPU passthrough (renderD128)
- Enables Docker features (nesting)
- Starts container

**After completion:**
- LXC103 running at `10.10.10.103`
- GPU device accessible at `/dev/dri/renderD128`
- Root password: "password" (change immediately!)

---

### Phase 2b: Docker & Portainer Agent on LXC103 (~10 min)

**Automated Docker and Portainer Agent installation.**

```bash
# Option 1: From Proxmox host
ssh -p 22022 ugreen-host "pct exec 103 -- bash -s" < /nvme2tb/lxc102scripts/ugreen-phase2-lxc103-docker.sh

# Option 2: SSH to LXC directly
ssh root@10.10.10.103
sudo bash /tmp/docker-setup.sh
```

**What this does:**
- Installs Docker CE
- Installs Docker Compose
- Sets timezone to Europe/Warsaw
- Deploys Portainer Agent
- Verifies GPU access from Docker
- Validates 8 installation checks

**After completion:**
- Portainer Agent at: `http://10.10.10.103:9001`
- Add as endpoint in Portainer UI

---

## Connecting LXC103 to Portainer

In Portainer web UI (https://10.10.10.100:9443):

1. **Settings** → **Endpoints**
2. **Add environment**
3. Fill in:
   - **Name:** `lxc-media` or `ugreen-media`
   - **Endpoint:** `http://10.10.10.103:9001`
   - **Group:** Media
4. **Connect**
5. Verify connection in Endpoints list

---

## Deploying Services via Portainer

After both VM100 and LXC103 are ready with Portainer, deploy services as Stacks:

### Infrastructure Services (VM100)

1. **Nginx Proxy Manager**
   - Required for all external access
   - Ports: 80, 443, 81

2. **Authentik** (needs PostgreSQL + Redis)
   - SSO provider
   - Integrates with Nginx PM

3. **Netbird**
   - Mesh VPN
   - External access without port forwarding

4. **Paperless-ngx** (needs PostgreSQL + Redis)
   - Document management

5. **SimpleLogin** (needs domain + DNS)
   - Email aliasing

6. **Uptime Kuma**
   - Monitoring dashboard

7-10. **Utilities:** Stirling PDF, Pairdrop, Nextexplorer

### Media Services (LXC103)

> **IMPORTANT:** Select LXC103 endpoint when deploying these

1. **Plex** (needs GPU for transcoding)
   - Hardware: `--device /dev/dri/renderD128`

2. **Jellyfin** (needs GPU for transcoding)
   - Hardware: `--device /dev/dri/renderD128`

3. **Sonarr** (TV automation)
4. **Radarr** (Movie automation)
5. **Prowlarr** (Indexer manager)
6. **Bazarr** (Subtitles)
7. **Lidarr** (Music automation)

---

## Storage Mounts

### LXC103 Media Storage

Mount 20TB SATA array for media:

```bash
# On Proxmox host, edit /etc/pve/lxc/103.conf:
mp0: /storage/Media,mp=/mnt/media,ro=0
```

Then restart LXC:
```bash
pct reboot 103
```

Inside LXC, verify:
```bash
mount | grep mnt/media
```

---

## Rollback Procedures

### VLAN 10 Rollback (Automatic)

If connectivity lost during Phase 0, the script auto-rollbacks:
```bash
# Restore from backup if needed (manual):
cp /root/network-backups/interfaces.backup-* /etc/network/interfaces
ifreload -a
```

### VM100 Rollback

If VM100 has issues:
```bash
# On Proxmox host:
qm stop 100
qm destroy 100
# Then re-run Phase 1a script
```

### LXC103 Rollback

If LXC103 has issues:
```bash
# On Proxmox host:
pct stop 103
pct destroy 103
# Then re-run Phase 2a script
```

---

## Log Files

All scripts create detailed logs:

- **Phase 0 (VLAN):** `/root/network-backups/vlan10-setup-*.log`
- **Phase 1a (VM100 create):** `/tmp/vm100-create-*.log`
- **Phase 1b (Docker):** VM100 → `/var/log/docker-setup-*.log`
- **Phase 2a (LXC103 create):** `/tmp/lxc103-create-*.log`
- **Phase 2b (Docker):** LXC103 → `/var/log/docker-setup-*.log`

---

## Troubleshooting

### Phase 0: VLAN Setup Fails

**Issue:** Network connectivity lost
- **Solution:** Script auto-rolls back. If manual recovery needed:
  ```bash
  cp /root/network-backups/interfaces.backup-* /etc/network/interfaces
  ifreload -a
  ```

### Phase 1b: Docker won't install

**Issue:** `curl: command not found` or GPG errors
- **Solution:** Ensure Ubuntu updated
  ```bash
  sudo apt-get update
  sudo apt-get install -y curl gnupg
  ```

### Phase 2b: GPU not accessible in LXC

**Issue:** `/dev/dri/renderD128` not visible
- **Solution:** Verify LXC config:
  ```bash
  cat /etc/pve/lxc/103.conf | grep "dev0"
  ```
  Should show: `dev0: /dev/dri/renderD128,gid=104`

### Portainer Agent won't connect

**Issue:** Endpoint offline in Portainer
- **Solution:** Verify agent is running:
  ```bash
  docker ps | grep portainer_agent
  ```
  And check connectivity from VM100:
  ```bash
  curl -s http://10.10.10.103:9001 | head
  ```

---

## Quick Reference Commands

```bash
# Check VLAN 10 status
ip addr show vmbr0.10

# Check VM100 status
qm status 100

# Check LXC103 status
pct status 103

# SSH to VM100
ssh admin@10.10.10.100

# SSH to LXC103
ssh root@10.10.10.103

# Access Portainer
https://10.10.10.100:9443

# Monitor Docker (VM100)
ssh admin@10.10.10.100 "docker ps -a"

# Monitor Docker (LXC103)
pct exec 103 -- docker ps -a

# Check logs (VM100)
ssh admin@10.10.10.100 "sudo tail -f /var/log/docker-setup-*.log"

# Check logs (LXC103)
pct exec 103 -- sudo tail -f /var/log/docker-setup-*.log
```

---

## Timeline Estimate

| Phase | Task | Duration | Type |
|-------|------|----------|------|
| 0 | VLAN setup | 10 min | Automated |
| 1a | VM100 create | 5 min | Automated |
| 1 | Ubuntu install | 20-30 min | Manual |
| 1b | Docker install | 10 min | Automated |
| **1c** | **VM100 hardening** | **~1.5 hours** | **Automated orchestration** |
| 2a | LXC103 create | 5 min | Automated |
| 2b | Docker install | 10 min | Automated |
| Services | Deploy via Portainer | 2-3 hours | Manual (UI clicks) |

**Total: ~4.5-5 hours infrastructure + ~2-3 hours service configuration**

**New:** Phase 1c production hardening now fully integrated and automated!

---

## File Locations

All scripts in bind-mount location:
- **Container path:** `/mnt/lxc102scripts/`
- **Proxmox host path:** `/nvme2tb/lxc102scripts/`

**Automation Scripts:**
- `ugreen-phase0-vlan10-setup.sh` - VLAN configuration
- `ugreen-phase1-vm100-create.sh` - VM creation
- `ugreen-phase1-vm100-docker.sh` - Docker/Portainer on VM
- `ugreen-phase1c-vm100-hardening-orchestrator.sh` - **NEW:** Production hardening (orchestrates Phase A scripts)
- `ugreen-phase2-lxc103-create.sh` - LXC creation with GPU
- `ugreen-phase2-lxc103-docker.sh` - Docker/Agent on LXC

**Supporting Files:**
- `UGREEN-AUTOMATION-README.md` - This comprehensive guide
- Phase A hardening scripts location: `/home/sleszugreen/scripts/vm100ugreen/hardening/` (Session 36)

---

## Support & Debugging

For issues, check:
1. Relevant log file (see Log Files section)
2. Network connectivity: `ping 192.168.40.1`
3. DNS: `nslookup github.com`
4. Docker errors: `docker logs <container-name>`
5. LXC errors: `pct exec 103 -- systemctl status docker`

---

**Last Updated:** 5 January 2026
**Automation Level:** 70%
**Manual Configuration:** 30%
