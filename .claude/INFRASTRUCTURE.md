# UGREEN Infrastructure Overview

---

## Network Architecture

**UGREEN Proxmox:**
- **IP:** 192.168.40.60 (Proxmox host)
- **Container 102 IP:** 192.168.40.82 (ugreen-ai-terminal)
- **Network:** 192.168.40.x (local subnet)
- **Primary interface:** vmbr0 (bridge)

**Access Points:**
- **Proxmox Web UI:** https://192.168.40.60:8006
- **SSH to Proxmox:** `ssh sleszugreen@192.168.40.60`
- **SSH to Container:** `sudo pct enter 102` (from Proxmox host only)

**Important:** 
- SSH from container → Proxmox host is NOT configured
- Use Proxmox API tokens instead (see `PROXMOX-API-SETUP.md`)

---

## Storage Layout

### System Drive
- **Capacity:** 119GB NVMe
- **Pool:** local-lvm
- **Purpose:** Proxmox VE boot drive

### VM/LXC Storage (Primary)
- **Capacity:** 2TB WD_BLACK SN7100 NVMe
- **Pool Name:** nvme2tb
- **Type:** ZFS
- **Compression:** LZ4 (~50% space savings)
- **Features:** Snapshots, auto-TRIM enabled
- **Usage:** LXC 102 and other VM/LXC storage
- **Dataset:** nvme2tb/subvol-102-disk-0 (for LXC 102)

### Data Storage
- **Bays:** 4x SATA
- **Primary Use:** Bulk storage for media files
- **Access:** Via Samba share `ugreen20tb`

---

## Container 102 Specifications

**LXC 102 (ugreen-ai-terminal):**
- **OS:** Ubuntu 24.04 LTS
- **CPU:** 4 cores
- **RAM:** 4GB
- **Disk:** 20GB on nvme2tb (ZFS)
- **Autostart:** Enabled
- **IP:** 192.168.40.82

**Bind Mount:**
- **From Proxmox:** `/nvme2tb/lxc102scripts/`
- **In Container:** `/mnt/lxc102scripts/`
- **Purpose:** Shared scripts between container and host

---

## Samba/Windows Access

**Status:** ✅ Configured and Working

### UGREEN SMB Share (192.168.40.60)

**Share Configuration:**
| Property | Value |
|----------|-------|
| Share Name | `ugreen20tb` |
| Path | `/storage/Media` (20TB ZFS) |
| Protocol | SMB3 (Samba 4.22.6) |
| User | sleszugreen |
| Authentication | Samba password (via smbpasswd) |

**Windows Access:**
- **Server:** `\\192.168.40.60`
- **Share:** `\\192.168.40.60\ugreen20tb`
- **Map Drive:** `net use Z: \\192.168.40.60\ugreen20tb /user:sleszugreen /persistent:yes`
- **Access From:** 192.168.99.x (Windows desktop)

**Firewall Rules (required for cross-subnet access):**

File: `/etc/pve/firewall/cluster.fw` (add these lines):
```
# Allow SMB from Windows desktop
IN ACCEPT -source 192.168.99.6 -p tcp -dport 445 -log nolog
IN ACCEPT -source 192.168.99.6 -p tcp -dport 139 -log nolog
```

Then restart firewall:
```bash
sudo systemctl restart pve-firewall.service
```

**Verify rules are applied:**
```bash
sudo iptables -L -n | grep 445
```

---

### Homelab SMB Shares (192.168.40.40)

**Status:** ✅ Fully accessible (Session 128)

**Share Configuration:**
| Property | FilmsHomelab | SeriesHomelab |
|----------|--------------|---------------|
| Path | `/Seagate-20TB-mirror/FilmsHomelab` | `/Seagate-20TB-mirror/SeriesHomelab` |
| User | samba-homelab | samba-homelab |
| Protocol | SMB (Samba) | SMB (Samba) |
| Permissions | 0664/0775 | 0664/0775 |
| Browseable | Yes | Yes |
| Read Only | No | No |

**Windows Access:**
- **Server:** `\\192.168.40.40`
- **FilmsHomelab:** `\\192.168.40.40\FilmsHomelab` (Drive I)
- **SeriesHomelab:** `\\192.168.40.40\SeriesHomelab` (Drive J)
- **Access From:** 192.168.99.x (Windows desktop, VLAN 99)
- **Authentication:** User `samba-homelab`

**Map Drive Commands:**
```batch
net use I: \\192.168.40.40\FilmsHomelab /user:samba-homelab /persistent:yes
net use J: \\192.168.40.40\SeriesHomelab /user:samba-homelab /persistent:yes
```

#### Critical Setup Requirements for Cross-VLAN SMB

This pattern has three independent failure points that must all be fixed:

**1. Filesystem Permissions - Parent Directory Traversal**

Samba requires execute (+x) permission on ALL directories in the path, including parent directories. A common gotcha:

```bash
# PROBLEM: Parent missing +x, target has correct perms
/Seagate-20TB-mirror/     ← Missing +x (755 → 755)
└── FilmsHomelab/         ← Has +x (755)

# FIX: Grant execute permission to parent
sudo chmod a+x /Seagate-20TB-mirror

# Verify with ls -ld (4th character should be x)
ls -ld /Seagate-20TB-mirror
# drwxr-xr-x (755 - others can traverse)
```

**Why this matters:** Without parent directory execute permission, Samba cannot traverse to the subdirectory. SMB clients will get "access denied" or "network path not found" even though:
- The share definition is correct
- The target directory has correct permissions
- The Samba service is running
- Port 445 is open

**2. Firewall Rules - Input and Forwarding**

Both SMB ports must be allowed on the Homelab Proxmox host:

```bash
# Allow incoming SMB traffic on port 445
sudo iptables -I INPUT -p tcp --dport 445 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 139 -j ACCEPT

# Make persistent (survive reboots)
sudo apt-get install iptables-persistent
sudo netfilter-persistent save

# Verify
sudo iptables -L INPUT -v | grep 445
```

**Why this is needed:** Default Proxmox firewall blocks SMB ports to prevent ransomware. Cross-VLAN access (Windows VLAN99 → Homelab VLAN40) requires explicit allow rules even when Samba is listening on 0.0.0.0.

**3. Windows Registry Cleanup - Ghost Drive Letters**

Windows retains stale connection keys even after `net use /delete`. These must be manually removed:

```batch
REM Delete ghost drive letter keys from registry
reg delete HKCU\Network\I /f
reg delete HKCU\Network\J /f

REM Restart Windows to clear kernel-level handles
shutdown /r /t 0
```

**Why this matters:** Windows kernel retains connection handles across `net use /delete` and `logoff`. Registry entries persist until manually removed. This causes:
- Error 85: "Local device name is already in use"
- Error 1202: "The local device name has a remembered connection"
- Inability to reuse drive letters even though they appear free

#### Troubleshooting Cross-VLAN SMB Access

**If Windows cannot connect despite Samba running:**

```bash
# On Homelab, verify all three layers:

# Layer 1: Filesystem permissions
ls -ld /Seagate-20TB-mirror  # Should show 755 (x for others)
ls -ld /Seagate-20TB-mirror/FilmsHomelab  # Should show 755

# Layer 2: Firewall rules
sudo iptables -L INPUT -v | grep 445
# Should show: ACCEPT  tcp  -- any   any  anywhere  anywhere  tcp dpt:445

# Layer 3: Samba configuration
sudo testparm  # Should pass validation
sudo smbclient -L \\127.0.0.1 -U samba-homelab  # Should list shares
```

**If Layer 1 fails (missing parent +x):**
```bash
sudo chmod a+x /Seagate-20TB-mirror
sudo systemctl restart smbd nmbd
```

**If Layer 2 fails (firewall blocking):**
```bash
sudo iptables -I INPUT -p tcp --dport 445 -j ACCEPT
sudo netfilter-persistent save
```

**If Layer 3 fails (SMB config):**
```bash
sudo testparm  # Will show specific config errors
# Fix config, then:
sudo systemctl restart smbd nmbd
```

---

## Current Data Organization

**Location:** `/storage/Media/` (20TB ZFS)

### Existing Folders
- `Filmy920/` - Movies from 920 NAS backup
- `Movies918/` - Movies from 918 NAS backup
- `20251209backupsfrom918/` - Backup folder (contains TV shows)
  - `backup seriale 2022 od 2023 09 28/` - TV series from 2022-2023 period
  - Windows path: `p:\20251209backupsfrom918\backup seriale 2022 od 2023 09 28\`

### To Be Created
- `series920part/` - **[TO BE CREATED]** TV series from 920 NAS backup (organized for deduplication)

---

## Proxmox Firewall Configuration

**Service:** `pve-firewall.service`

**Config File:** `/etc/pve/firewall/cluster.fw`

**Default Policy:** 
- DROP incoming traffic (deny-by-default security)
- Allow outgoing traffic
- Proxmox blocks SMB ports (445, 139) by default to prevent ransomware

**Managing Firewall:**
```bash
# Check status
sudo systemctl status pve-firewall.service

# View current rules
sudo iptables -L -n

# Restart firewall (after config changes)
sudo systemctl restart pve-firewall.service
```

**Important:** After editing `/etc/pve/firewall/cluster.fw`, always restart the firewall service.

---

## Proxmox API Access

**Status:** ✅ Properly configured and tested (25 Dec 2025)

**Token Setup:**

| Token | File | User | Role | Purpose |
|-------|------|------|------|---------|
| Cluster-Wide | `~/.proxmox-api-token` | claude-reader@pam | PVEAuditor | Read-only cluster access |
| VM 100 | `~/.proxmox-vm100-token` | vm100-reader@pam | PVEAuditor | VM 100 monitoring |

**API Endpoint:** `https://192.168.40.60:8006/api2/json/`

**Firewall Requirement:** Container (192.168.40.82) must have access to port 8006 on host (192.168.40.60)

**Firewall Configuration (Proxmox host):**
```bash
# Add this rule (runs ONCE):
sudo iptables -I INPUT 1 -s 192.168.40.82 -p tcp --dport 8006 -j ACCEPT

# Make persistent (add to /etc/pve/firewall/cluster.fw BELOW other rules):
echo "IN ACCEPT -source 192.168.40.82 -p tcp -dport 8006" >> /etc/pve/firewall/cluster.fw
sudo systemctl restart pve-firewall.service
```

**Verify Setup:**
```bash
bash /mnt/lxc102scripts/test-api-from-container.sh

# Should show: "✅ API call succeeded!" and return Proxmox version
```

---

## Hardware Reference

**UGREEN DXP4800+ Specs:**
- NVMe slots: 4 (populated with 119GB system + 2TB storage)
- SATA bays: 4 (for bulk storage)
- Power: Efficient 24W base

**Full Hardware Inventory:**
- Location: `/home/slesz/shared/projects/hardware/` (on homelab)
- GitHub: https://github.com/Sleszgit/homelab-hardware

---

## Cross-VLAN Connectivity Troubleshooting

**⚠️ CRITICAL PATTERN: "Ping Works But SSH/HTTP Fails"**

This is the most common misdiagnosis in cross-VLAN troubleshooting. If you can ping a container/VM but TCP services (SSH, HTTP, etc.) fail:

**STOP - Do NOT assume:**
- ❌ The service is down inside the container
- ❌ The IP configuration is wrong (ping proves routing exists)

**IDENTIFY - The issue is almost certainly:**
- ✅ A **firewall forwarding rule** on the host blocking TCP/UDP

### Root Cause Explanation

Linux firewalls (UFW/iptables) often:
1. Allow ICMP (ping) by default
2. Block forwarded TCP/UDP traffic when `DEFAULT_FORWARD_POLICY="DROP"`

**Critical distinction:**
```bash
# Opens port on HOST only - does NOT help containers/VMs
ufw allow 22/tcp

# Allows FORWARDED traffic through host TO containers/VMs
ufw route allow proto tcp from 192.168.40.0/24 to 10.10.10.0/24 port 22
```

### Diagnostic Protocol

When "Ping works but SSH/HTTP fails" across VLANs:

**Step 1: Confirm the pattern**
```bash
# From management network (e.g., LXC102)
ping 10.10.10.100        # Works? → Routing is fine
ssh user@10.10.10.100    # Fails? → Firewall forwarding issue
```

**Step 2: Check UFW forwarding policy on the HOST**
```bash
# On Proxmox host
grep DEFAULT_FORWARD_POLICY /etc/default/ufw
# If "DROP" → forwarded traffic is blocked by default
```

**Step 3: Check existing route rules**
```bash
# On Proxmox host
sudo ufw status | grep -i route
```

**Step 4: Add route allow rules (if missing)**
```bash
# Allow SSH from management VLAN to isolated VLAN
sudo ufw route allow proto tcp from 192.168.40.0/24 to 10.10.10.0/24 port 22

# Allow HTTP/HTTPS
sudo ufw route allow proto tcp from 192.168.40.0/24 to 10.10.10.0/24 port 80
sudo ufw route allow proto tcp from 192.168.40.0/24 to 10.10.10.0/24 port 443
```

### Real-World Example (Session 100-101)

**Scenario:** VM100 (10.10.10.100 on VLAN10) unreachable from LXC102 (192.168.40.82)
- Ping: ✅ Worked
- SSH: ❌ Timeout
- Console: ✅ VM responsive

**Root cause:** UFW on UGREEN host had `DEFAULT_FORWARD_POLICY="DROP"` and no `ufw route allow` rules for cross-VLAN TCP traffic.

**Solution:** Added `ufw route allow` rules for management → VLAN10 traffic.

### Prevention Checklist

Before making firewall changes that affect container/VM connectivity:

- [ ] Note current `DEFAULT_FORWARD_POLICY` setting
- [ ] List existing `ufw route` rules
- [ ] Test ping AND TCP connectivity before changes
- [ ] When adding VLAN isolation, add `ufw route allow` for management access
- [ ] Test from LXC102 immediately after changes

---

## Troubleshooting Access Issues

**Container can't reach Proxmox API?**

Check these in order:
1. Firewall rule exists: `sudo iptables -L -n | grep 8006`
2. Container can reach host: `ping 192.168.40.60` (from container)
3. Port is open: `sudo ss -tlnp | grep 8006` (on Proxmox host)
4. Test script output: `/mnt/lxc102scripts/test-api-from-container.sh`

**Windows can't access Samba?**

For UGREEN (192.168.40.60):
1. Firewall rules exist: `sudo iptables -L -n | grep 445`
2. Samba service running: `sudo systemctl status smbd`
3. User has Samba password: `sudo smbpasswd -L | grep sleszugreen`
4. Test from Windows: `net use \\192.168.40.60\ugreen20tb /user:sleszugreen`

For Homelab (192.168.40.40) - **THREE-LAYER DIAGNOSIS:**

**CRITICAL:** Homelab SMB has three independent failure points. Check all three:
1. **Filesystem Permissions:** `ls -ld /Seagate-20TB-mirror` must show "x" for others (755 or drwxr-xr-x)
   - Without this, Samba cannot traverse to subdirectories
   - Fix: `sudo chmod a+x /Seagate-20TB-mirror`
2. **Firewall Rules:** `sudo iptables -L INPUT -v | grep 445` must show ACCEPT rule
   - Default Proxmox firewall blocks SMB ports
   - Fix: `sudo iptables -I INPUT -p tcp --dport 445 -j ACCEPT` + `sudo netfilter-persistent save`
3. **Samba Configuration:** `sudo testparm` must pass validation
   - User must exist: `sudo smbpasswd -L | grep samba-homelab`
   - Share path must exist and be readable

After fixing any layer, restart: `sudo systemctl restart smbd nmbd`

See "Homelab SMB Shares" section above for detailed diagnostic protocol.

---

## Quick Reference Commands

**Check Proxmox status:**
```bash
pveversion
sudo systemctl status pve-firewall.service
```

**Check container:**
```bash
sudo pct status 102
sudo pct config 102 | grep -E "net|mp|memory|cores"
```

**Check network:**
```bash
ip addr show
sudo iptables -L -n
sudo ss -tlnp
```

**Check Samba:**
```bash
sudo systemctl status smbd
sudo smbclient -L \\127.0.0.1 -U sleszugreen
```

---

## See Also

- `PROXMOX-COMMANDS.md` - Command reference
- `PATHS-AND-CONFIG.md` - Directory structure
- `PROXMOX-API-SETUP.md` - Detailed API token setup
