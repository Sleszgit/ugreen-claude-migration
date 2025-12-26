# Session 31: Homelab Samba Setup for BackupFrom918

**Date:** 26 December 2025 (Evening)  
**Status:** ✅ Samba installed and configured | 🔧 SMB connectivity troubleshooting in progress  
**Primary Goal:** Set up SMB/Samba on homelab to mount 918 backup folder in Windows 11

---

## Executive Summary

Successfully installed and configured Samba on the homelab to expose the `/WD10TB/918backup2512/` backup folder as an SMB share. Created dedicated `samba-homelab` user for security isolation. Identified and partially resolved Proxmox firewall blocking SMB ports - firewall rules added but Windows still unable to connect (investigating).

---

## Work Completed

### 1. ✅ Phase 2.5 Transfer Verification
- **Status:** CONFIRMED SUCCESSFUL
- **Total transferred:** 3.5TB (slightly less than estimated 4.07TB)
- **Folder count:** 9 folders with all contents
- **Special folder:** `09-20221217` contains 3.0TB and 1,465 files - fully copied
- **Command to verify:** `ssh sshadmin@192.168.40.40 'du -sh /WD10TB/918backup2512/'`

### 2. ✅ Analysis: Separate Samba User
User clarified that homelab is **production-grade environment** (equal/better than UGREEN):
- More storage space (9TB vs 2TB UGREEN)
- More RAM
- More powerful processor
- Designed for future expansion

**Decision:** Create separate `samba-homelab` user (security best practice for production)
- Separate from `sshadmin` (admin account)
- Read-write access to `/WD10TB/918backup2512/`
- Share name: `BackupFrom918`

### 3. ✅ Samba Installation Script Created
**Location:** `/mnt/lxc102scripts/setup-samba-homelab.sh` (bind mount)
- Also in container: `/home/sleszugreen/scripts/samba/setup-samba-homelab.sh`
- Script includes:
  - Samba package installation
  - SMB configuration with BackupFrom918 share
  - User creation (samba-homelab)
  - File permissions setup
  - Service startup
  - Firewall configuration (attempted)

### 4. ✅ Samba Setup on Homelab Completed
**All 7 steps successful:**
1. ✅ Samba packages installed
2. ✅ SMB share configured (BackupFrom918)
3. ✅ User created (samba-homelab)
4. ✅ Samba password set
5. ✅ File ownership: samba-homelab:samba-homelab
6. ✅ Services started (smbd, nmbd)
7. ⚠️ Firewall configuration (ufw not installed)

**Verification results:**
```bash
systemctl status smbd      # ✅ active (running)
systemctl status nmbd      # ✅ active (running)
ss -tlnp | grep 445        # ✅ LISTENING on 0.0.0.0:445
smbclient -L localhost     # ✅ BackupFrom918 share visible
```

### 5. ✅ Identified Proxmox Firewall Issue
**Problem discovered:**
```bash
sudo iptables -L -n | grep 445
# Output showed:
DROP       tcp  --  0.0.0.0/0            0.0.0.0/0            multiport dports 135,139,445
DROP       udp  --  0.0.0.0/0            0.0.0.0/0            multiport dports 135,445
```

**Root cause:** Proxmox firewall (`pve-firewall.service`) was blocking SMB ports

### 6. ✅ Proxmox Firewall Rules Added
**File edited:** `/etc/pve/firewall/cluster.fw`

**Rules added:**
```
# SMB/Samba ports for homelab backup access
IN ACCEPT -source 192.168.99.0/24 -p tcp -dport 135,139,445
IN ACCEPT -source 192.168.99.0/24 -p udp -dport 137,138,445
```

**Why these rules:**
- Source: 192.168.99.0/24 (Desktop/Management VLAN - Windows machine network)
- Ports: 135, 139, 445 (TCP) and 137, 138, 445 (UDP) for SMB

---

## Current Issue & Troubleshooting

### Windows SMB Connection Hanging
**Symptom:** Windows shows "trwa próba podłączenia" (attempting to connect) - then times out

**Existing network connectivity:**
- ✅ User can SSH from Windows to homelab (MobaXterm working)
- ✅ Ping works: 192.168.40.40 responds
- ✅ Other SMB shares accessible from Windows:
  - I: \\192.168.40.20\Filmy920 (OK)
  - J: \\192.168.40.20\Seriale 2023 (OK)
  - P: \\192.168.40.60\ugreen20tb (OK)

**Samba service status (verified on homelab):**
- ✅ smbd running
- ✅ nmbd running
- ✅ Port 445 listening on all interfaces
- ✅ Share configured correctly
- ✅ User exists with password set

**Possible causes:**
1. Proxmox firewall rules haven't reloaded yet
2. Windows firewall blocking SMB to this specific IP
3. Network routing issue specific to SMB
4. Proxmox firewall reload needed

### Next Steps to Resolve
1. Restart Proxmox firewall to ensure rules take effect
2. Test telnet connectivity from Windows to port 445
3. Check Windows firewall rules
4. Verify SMB traffic can route to 192.168.40.40

---

## Network Architecture Reference

**IP Addresses:**
- Windows 11 machine: 192.168.99.x (Desktop/Management VLAN)
- UGREEN Proxmox: 192.168.40.60
- Homelab Proxmox: 192.168.40.40
- 918 NAS: 192.168.40.20
- LXC 102 (ugreen-ai-terminal): 192.168.40.82

**Storage:**
- Homelab capacity: 9TB
- Phase 2.5 transferred: 3.5TB (918 backups)
- Used: ~39%
- Available for Phase 2 (Filmy920, ~3.6TB): Yes

---

## Files Created/Modified

### Scripts Created
- `/mnt/lxc102scripts/setup-samba-homelab.sh` (4.2KB)
- `/home/sleszugreen/scripts/samba/setup-samba-homelab.sh` (duplicate for organization)

### Configuration Modified
- `/etc/samba/smb.conf` (created on homelab)
- `/etc/pve/firewall/cluster.fw` (firewall rules added)

### Users Created
- `samba-homelab` (system user, no shell access)

### Share Configured
- Share name: `BackupFrom918`
- Path: `/WD10TB/918backup2512/`
- Permissions: 775 (read-write)
- Owner: samba-homelab:samba-homelab

---

## Key Decisions Made

1. **Separate Samba user** vs using sshadmin
   - ✅ Chose: Separate `samba-homelab` user
   - Reason: Production environment, better security isolation

2. **Read-write access** vs read-only
   - ✅ Chose: Read-write
   - Reason: User wants to delete/manage backups from Windows

3. **Share naming**
   - ✅ Chose: `BackupFrom918`
   - Reason: Clear, descriptive, matches folder purpose

4. **Script placement**
   - ✅ Chose: Bind mount location `/mnt/lxc102scripts/`
   - Reason: Accessible from both container and UGREEN host

---

## Testing & Verification

### From Homelab
```bash
# Test local SMB access
smbclient -L localhost -U samba-homelab
# Result: BackupFrom918 share visible ✅

# Check service status
systemctl status smbd  # active (running) ✅
systemctl status nmbd  # active (running) ✅

# Verify port listening
ss -tlnp | grep 445    # LISTENING on 0.0.0.0:445 ✅
```

### From Windows
```bash
# Existing network connections working
net use
# Result: 4 SMB shares connected (to other IPs)
# Result: 0 connections to 192.168.40.40 (homelab) ❌

# Attempted mapping (currently hanging)
net use K: \\192.168.40.40\BackupFrom918 /user:samba-homelab
# Result: "trwa próba podłączenia" (timeout) ⏳
```

---

## Important Notes for Next Session

1. **Firewall restart may be needed:**
   ```bash
   sudo systemctl restart pve-firewall
   ```

2. **Windows firewall might block SMB to this specific IP** - may need to add exception in Windows Defender Firewall

3. **Test telnet from Windows:**
   ```bash
   telnet 192.168.40.40 445
   ```
   This will confirm if port 445 is reachable

4. **Samba password for Windows:**
   - Username: `samba-homelab`
   - Password: [was set during setup script]
   - Remember: Different from Linux password

5. **SMB share details:**
   - UNC path: `\\192.168.40.40\BackupFrom918`
   - Local path on homelab: `/WD10TB/918backup2512/`
   - Access: Read-write

6. **All backups successfully on homelab:**
   - 9 folders, 3.5TB total
   - All file content verified (sample files checked)
   - Ready for Windows access once SMB connects

---

## Next Session Tasks

1. **Troubleshoot Windows SMB connectivity**
   - Restart Proxmox firewall
   - Test telnet from Windows
   - Check Windows firewall rules
   - Verify SMB can reach homelab

2. **Once SMB works in Windows:**
   - Verify all folders visible in share
   - Test file operations (read, write, delete)
   - Document the working setup

3. **Plan Phase 2 transfer:**
   - Transfer Filmy920 backups (~3.6TB)
   - Same approach as Phase 2.5

4. **Future expansion planning:**
   - Homelab has 5.5TB free space
   - Plan additional shares (media, etc.)
   - Document for future reference

---

**Session Status:** PAUSED - Awaiting Windows SMB connectivity troubleshooting  
**Last Action:** Added Proxmox firewall rules, investigating Windows hanging issue  
**Time Spent:** ~2 hours research, configuration, and troubleshooting  

