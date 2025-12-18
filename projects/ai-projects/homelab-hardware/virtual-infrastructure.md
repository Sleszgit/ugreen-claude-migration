# Virtual Infrastructure Inventory

**Last Updated:** 2025-12-18

This file contains all **virtual infrastructure** running on the homelab. This includes VMs, LXC containers, services, and network topology. This file changes frequently as services are added/removed.

---

## Proxmox Virtual Machines (VMs)

### VM 100: docker-services

**Type:** Virtual Machine (Proxmox)
**VMID:** 100
**Status:** Running
**OS:** Ubuntu Server
**Network IP:** 10.10.10.10 (Secondary network)
**Managed by:** Portainer (ubuntu-docker-services environment)

**Specifications:**
- **RAM:** 32 GB
- **Boot Disk:** 120 GB
- **SSH Access:** Yes
- **Portainer Agent:** Port 9001
- **Auto-start:** Configured

**Running Docker Containers:**
- **Kavita** - Manga/comic reader
  - Port: 5000
  - URL: http://10.10.10.10:5000/
- **Audiobookshelf** - Audiobook server
  - Port: 13378
  - URL: http://10.10.10.10:13378/
- **Portainer Agent**
  - Port: 9001
  - Connects to: Portainer on UGREEN (192.168.40.60:9999)

**Purpose:**
- Dedicated media services VM
- Docker container host
- Isolated from primary network (10.10.10.x subnet)

---

## Proxmox LXC Containers

### LXC 101: immich

**Type:** LXC Container (Proxmox)
**VMID:** 101
**Status:** Running
**OS:** Debian/Ubuntu-based
**Purpose:** Immich photo management system
**Network:** 192.168.40.x (primary network)
**Managed by:** Portainer (immich-lxc environment)

**Services:**
- Immich photo backup and management
- Web interface (port TBD)
- Mobile app backend
- AI-powered photo organization
- Face recognition
- Automatic backup from mobile devices

**Storage:**
- Photo library storage
- Thumbnail cache
- Database (PostgreSQL)
- Machine learning models

**Purpose:**
- Self-hosted Google Photos alternative
- Family photo backup and sharing
- Automatic mobile photo backup

---

### LXC 102: ai-terminal (UGREEN Instance)

**Type:** LXC Container (Proxmox)
**VMID:** 102
**Status:** Running
**OS:** Ubuntu 24.04 LTS
**Network IP:** 192.168.40.82 (primary network)
**Purpose:** Claude Code AI assistant host (UGREEN-specific instance)
**Host:** UGREEN DXP4800+ Proxmox (192.168.40.60)

**Specifications:**
- **User:** sleszugreen (sudo access)
- **CPU:** 4 cores
- **RAM:** 4GB
- **Storage:** 20GB on nvme2tb (ZFS with LZ4 compression)
  - Storage pool: nvme2tb/subvol-102-disk-0
  - Filesystem: ZFS with auto-TRIM
  - Compression: LZ4 (~50% space savings)
- **SSH Access:** Yes (port 22)
- **SSH Command:** `ssh sleszugreen@192.168.40.82`
- **Auto-start:** Enabled
- **Boot Time:** ~30 seconds until SSH ready

**Services:**
- Claude Code CLI (auto-updates on login)
- SSH server
- AI-assisted development environment
- Auto-update system (~/scripts/auto-update/.auto-update.sh)

**Migration History:**
- **2025-12-18:** Migrated from local-lvm (119GB system NVMe) to nvme2tb (2TB WD_BLACK SN7100)
- Backup location: /var/lib/vz/dump/vzdump-lxc-102-2025_12_18-15_31_44.tar.zst (Proxmox host)

**Important Notes:**
- Allow 30 seconds after container boot before SSH is fully accessible
- Network must be fully initialized before SSH works
- Used for AI-assisted UGREEN Proxmox infrastructure management
- ZFS snapshots available for quick rollbacks (see SESSION-LXC102-MIGRATION-20251218.md)
- This is the UGREEN instance - separate from homelab LXC 102 (192.168.40.37)

---

### LXC 200: netbox

**Type:** LXC Container (Proxmox)
**VMID:** 200
**Status:** Running
**OS:** Debian/Ubuntu-based
**Network:** 192.168.40.x (primary network)
**Purpose:** Network documentation and IPAM (IP Address Management)

**Services:**
- NetBox web interface (port TBD)
- Network topology documentation
- IP address management (IPAM)
- Device inventory
- Cable management
- Virtual machine inventory
- Contact and tenant tracking

**Purpose:**
- Central source of truth for network infrastructure
- Document all devices, IPs, VLANs, connections
- Track hardware inventory
- Network change management

---

## Network Configuration

### Primary Network: 192.168.40.x

**Purpose:** Main homelab network for most services

**Devices on this network:**
- UGREEN Proxmox: **192.168.40.60** (host)
- LXC 102 (ai-terminal, UGREEN): **192.168.40.82**
- LXC 102 (ai-terminal, homelab): **192.168.40.37**
- LXC 101 (immich): IP TBD
- LXC 200 (netbox): IP TBD
- Synology DS918+: IP TBD
- Synology DS920+: IP TBD
- Raspberry Pi 400: IP TBD
- Raspberry Pi 3B: IP TBD
- Proxmox host (pve, homelab): IP TBD

**Subnet:** 192.168.40.0/24 (likely)
**Gateway:** TBD
**DNS:** TBD

---

### Secondary Network: 10.10.10.x

**Purpose:** Isolated network for specific services (docker-services VM)

**Devices on this network:**
- VM 100 (docker-services): **10.10.10.10**

**Subnet:** 10.10.10.0/24 (likely)
**Gateway:** TBD
**DNS:** TBD

**Note:** Networks can communicate with each other (routing configured between 192.168.40.x and 10.10.10.x)

---

## Portainer Environments

**Portainer Server Location:** http://192.168.40.60:9999/ (UGREEN NAS)

**Managed Environments:**

1. **local** (UGREEN itself)
   - Type: Direct connection
   - Purpose: Manage Docker containers on UGREEN NAS

2. **Pi400**
   - Type: Portainer Agent
   - Device: Raspberry Pi 400
   - Agent Port: 9001

3. **pi3B**
   - Type: Portainer Agent
   - Device: Raspberry Pi 3B
   - Agent Port: 9001

4. **immich-lxc**
   - Type: Portainer Agent
   - Device: LXC 101 (immich)
   - Agent Port: 9001

5. **ubuntu-docker-services**
   - Type: Portainer Agent
   - Device: VM 100 (docker-services)
   - IP: 10.10.10.10
   - Agent Port: 9001

---

## Service Catalog

**Active Services and Access URLs:**

### Management Interfaces
- **Portainer Server:** http://192.168.40.60:9999/ (UGREEN NAS)
- **Proxmox VE:** https://[proxmox-ip]:8006/ (web UI)
- **Synology DSM (DS918+):** https://[ds918-ip]:5001/ (HTTPS) or http://[ds918-ip]:5000/ (HTTP)
- **Synology DSM (DS920+):** https://[ds920-ip]:5001/ (HTTPS) or http://[ds920-ip]:5000/ (HTTP)
- **UGREEN UGOS:** http://192.168.40.60:[port]/ (web UI)

### Application Services
- **Kavita (Manga/Comics):** http://10.10.10.10:5000/ (VM 100)
- **Audiobookshelf:** http://10.10.10.10:13378/ (VM 100)
- **Immich (Photos):** http://[lxc-101-ip]:[port]/ (LXC 101)
- **NetBox (Network Docs):** http://[lxc-200-ip]:[port]/ (LXC 200)
- **Claude Code (AI):** ssh slesz@192.168.40.37 (LXC 102)

---

## Resource Allocation Summary

### Proxmox Host Resources
- **Total Physical RAM:** 96 GB DDR5
- **Total CPU Cores:** 14 cores (6P + 8E)
- **Total Storage:** 1TB NVMe + expansion bays

### Allocated Resources

| VM/LXC | Type | RAM | Disk | CPU Cores | Network |
|--------|------|-----|------|-----------|---------|
| VM 100 (docker-services) | VM | 32 GB | 120 GB | TBD | 10.10.10.10 |
| LXC 101 (immich) | LXC | TBD | TBD | TBD | 192.168.40.x |
| LXC 102 (ai-terminal) | LXC | TBD | TBD | TBD | 192.168.40.37 |
| LXC 200 (netbox) | LXC | TBD | TBD | TBD | 192.168.40.x |

**Total Allocated RAM:** 32+ GB (out of 96 GB available)
**Remaining for new VMs/LXCs:** ~64 GB

---

## Backup Strategy

**Backup Hosts:**
- Synology DS920+ (GitHub backup automation)
- Need to verify backup script locations and GitHub token status

**Services Backed Up:**
- Nginx configs
- Other service configs
- Combined into 1 GitHub repository

**Known Issues:**
- GitHub backups stopped working months ago (last backup: Aug/Sept 2025)
- Suspected expired GitHub Personal Access Token
- Need to locate backup scripts and renew tokens

---

## Network Diagram (Text Format)

```
Internet
   |
   v
Router/Gateway
   |
   +--- [192.168.40.x Network] ---------------------------+
   |                                                       |
   +-- UGREEN Proxmox (192.168.40.60)                     |
   |      +-- LXC 102: ai-terminal (192.168.40.82)        |
   |      +-- LXC 101: immich                             |
   |      +-- LXC 200: netbox                             |
   +-- Homelab Proxmox (pve)                              |
   |      +-- LXC 102: ai-terminal (192.168.40.37)        |
   +-- Synology DS918+                                    |
   +-- Synology DS920+                                    |
   +-- Raspberry Pi 400 (Portainer Agent)                 |
   +-- Raspberry Pi 3B (Portainer Agent)                  |
   |                                                       |
   +-------------------------------------------------------+
   |
   +--- [10.10.10.x Network] -----------------------------+
   |                                                       |
   +-- VM 100: docker-services (10.10.10.10)              |
   |      +-- Kavita (port 5000)                          |
   |      +-- Audiobookshelf (port 13378)                 |
   |      +-- Portainer Agent (port 9001)                 |
   |                                                       |
   +-------------------------------------------------------+

Networks can communicate with each other (routing enabled)

NOTE: There are TWO separate LXC 102 containers (both named "ai-terminal"):
- UGREEN instance: 192.168.40.82 (user: sleszugreen)
- Homelab instance: 192.168.40.37 (user: slesz)
```

---

## Maintenance Commands

**Proxmox Host (requires sudo as sshadmin):**

```bash
# List all LXC containers
sudo pct list

# List all VMs
sudo qm list

# Start/stop LXC container
sudo pct start <VMID>
sudo pct stop <VMID>

# Start/stop VM
sudo qm start <VMID>
sudo qm shutdown <VMID>

# Enter LXC container console
sudo pct enter <VMID>

# Check LXC container config
sudo pct config <VMID>

# Check VM config
sudo qm config <VMID>

# Enable auto-start
sudo pct set <VMID> --onboot 1
sudo qm set <VMID> --onboot 1
```

---

## Notes for LLMs

**About Virtual Infrastructure:**
- This file contains VMs, LXCs, services, network topology (changes frequently)
- For physical hardware specs → see `physical-hardware.md`
- **ALWAYS use `sudo`** for Proxmox pct/qm commands (user: sshadmin)
- User prefers **web UI management** (Portainer, Proxmox web UI)
- User wants **monitoring and visibility** - suggest dashboard solutions
- User is **learning** - explain concepts clearly
- **Wait 30 seconds** after LXC boot before expecting SSH connectivity

**When adding new services:**
- Include backup to GitHub in the solution
- Prefer Docker Compose over raw Docker commands
- Use Portainer for management when possible
- Document service URLs and default credentials
- Consider resource allocation (RAM, CPU, storage)
