# Session 7 - LXC 102 SSH Troubleshooting

**Date:** December 13, 2025
**Issue:** SSH access to LXC 102 as sleszugreen user is broken
**Status:** ROOT CAUSE INVESTIGATION IN PROGRESS

---

## Problem Summary

Cannot SSH into LXC 102 (192.168.40.81) as user `sleszugreen`. SSH asks for password instead of using key authentication.

### Working Access:
- ✅ Proxmox host SSH as root (192.168.40.60)
- ✅ LXC console access via `pct exec 102`

### Broken Access:
- ❌ SSH to LXC 102 as sleszugreen (192.168.40.81)

---

## Timeline of Events

1. **Dec 13 06:16** - Bind mount created for `/home/sleszugreen/projects/proxmox-hardening`
2. **Dec 13 06:19** - `.ssh` directory timestamp (modified/accessed?)
3. **Dec 13 06:28** - Fix scripts created (`fix-lxc-mount.sh`, `fix-lxc-ssh.sh`)
4. **Current** - SSH still broken, investigating root cause

---

## Bind Mount Configuration

### LXC 102 Config (`/etc/pve/lxc/102.conf`):
```
arch: amd64
cores: 4
features: nesting=1
hostname: ugreen-ai-terminal
memory: 4096
net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:F2:74:C4,ip=dhcp,type=veth
onboot: 1
ostype: ubuntu
rootfs: local-lvm:vm-102-disk-0,size=20G
startup: order=1,up=0,down=60
swap: 512
unprivileged: 1
mp0: /root/proxmox-hardening-source,mp=/home/sleszugreen/projects/proxmox-hardening
```

### Mount Details:
- **Host path:** `/root/proxmox-hardening-source` (owned by root:root)
- **Container path:** `/home/sleszugreen/projects/proxmox-hardening` (shows as nobody:nogroup)
- **Container type:** Unprivileged (UID/GID mapping active)
- **Issue:** Files appear as nobody:nogroup inside container due to UID mapping

---

## Current State Analysis

### Home Directory Permissions (Inside LXC 102):
```
drwxr-x--- 11 sleszugreen sleszugreen   4096 Dec 13 06:42 /home/sleszugreen
drwx------  2 sleszugreen sleszugreen   4096 Dec 13 06:19 /home/sleszugreen/.ssh
drwxrwxr-x  3 sleszugreen sleszugreen   4096 Dec 13 06:40 /home/sleszugreen/projects
drwxr-xr-x  3 nobody      nogroup       4096 Dec 13 06:16 /home/sleszugreen/projects/proxmox-hardening
```

### .ssh Directory Contents:
```
total 12
drwx------  2 sleszugreen sleszugreen 4096 Dec 13 06:19 .
drwxr-x--- 11 sleszugreen sleszugreen 4096 Dec 13 06:42 ..
-rw-r--r--  1 sleszugreen sleszugreen  284 Dec 13 06:26 known_hosts
```

**⚠️ CRITICAL: `authorized_keys` file is MISSING!**

### SSH Key Backups Found:
Located in bind mount backup directory:
- `/home/sleszugreen/projects/proxmox-hardening/backups/authorized_keys.backup.20251209_192755`
- `/home/sleszugreen/projects/proxmox-hardening/backups/authorized_keys.backup.20251209_192918` (newer, has 2 keys)

### Backup Keys Content:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgl2Px9CzHRCMpURrN5x/EwMOgY7cv... root@ugreen
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMv5ZdKSB8NrjRa04LAK1ePTpnnApTyC44RCxoJSp1a+ desktop-ugreen-nas
```

---

## Investigation Questions (UNANSWERED)

### Critical Question from User:
**"Why are you analyzing the SSH keys situation when some time ago you yourself wrote that the mount of folders in the LXC causes the failure of login of sleszugreen user by SSH?"**

This is a valid concern that needs investigation:

1. **How did the bind mount cause the SSH failure?**
   - Did it delete/overwrite the `authorized_keys` file?
   - Did it corrupt permissions on the home directory?
   - Did it cause some cascading permission issue?

2. **What was in the original fix attempts?**
   - Need to review: `fix-lxc-mount.sh`
   - Need to review: `fix-lxc-ssh.sh`
   - What did we try before?

3. **Can we prevent this from happening again?**
   - Is the bind mount configuration correct?
   - Do we need UID/GID mapping adjustments?
   - Should we use a different mounting approach?

---

## Files Created This Session

### On Proxmox Host:
- `/root/setup-bind-mount.sh` - Script that set up the bind mount
- `/root/diagnose-lxc.sh` - Diagnostic script

### Inside LXC 102:
- `~/scripts/infrastructure/fix-lxc-ssh-access.sh` - SSH key restoration script (CREATED BUT NOT RUN)
- `~/docs/sessions/SESSION-7-SSH-TROUBLESHOOTING.md` - This file

---

## Next Steps (NOT YET COMPLETED)

### Step 1: Understand Root Cause
Before fixing, we need to understand WHY the mount broke SSH:
```bash
# Review previous fix attempts
cat ~/scripts/infrastructure/fix-lxc-mount.sh
cat ~/scripts/infrastructure/fix-lxc-ssh.sh

# Check if there are any error logs
pct exec 102 -- journalctl -xe | grep -i ssh
pct exec 102 -- tail -100 /var/log/auth.log
```

### Step 2: Fix SSH Access
Once we understand the root cause, restore `authorized_keys`:
```bash
# Copy fix script to host
pct pull 102 ~/scripts/infrastructure/fix-lxc-ssh-access.sh /root/fix-lxc-ssh-access.sh

# Run the fix
bash /root/fix-lxc-ssh-access.sh
```

### Step 3: Fix Bind Mount Permissions (Optional)
If needed, implement UID/GID mapping or alternative solution.

### Step 4: Test and Verify
```bash
# From Windows
ssh -i C:\Users\jakub\.ssh\ugreen_key sleszugreen@192.168.40.81
```

---

## Important Notes

### Safety Considerations:
- ✅ Fix script ONLY touches LXC 102 container
- ✅ Proxmox host root SSH access will NOT be affected
- ✅ All commands use `pct exec 102` (container-only)
- ✅ Current state backed up before any changes

### Emergency Access:
If something goes wrong:
1. Proxmox host SSH: `ssh root@192.168.40.60` (still works)
2. LXC console: `pct enter 102` (from host)
3. Web UI Shell: https://192.168.40.60:8006

---

## Technical Details

### Container Info:
- **Container ID:** 102
- **IP Address:** 192.168.40.81
- **Type:** Unprivileged
- **OS:** Ubuntu
- **Status:** Running

### User Info:
- **Username:** sleszugreen
- **UID inside container:** 1000
- **GID inside container:** 1000
- **Home directory:** `/home/sleszugreen`

### UID/GID Mapping:
- No custom mapping configured
- Default unprivileged mapping active
- Host UID 0 → Container UID 100000
- Host UID 1000 → Container UID 101000
- Container UID 1000 → Host UID 101000

---

## Session Status

**Status:** PAUSED - Awaiting investigation of root cause
**Next Action:** Review previous fix scripts and understand how mount broke SSH
**Blocker:** Need to answer user's question about mount → SSH failure causation

---

**End of Session 7 Summary**
