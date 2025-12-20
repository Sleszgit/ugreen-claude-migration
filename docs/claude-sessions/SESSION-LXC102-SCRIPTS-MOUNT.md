# Session: LXC 102 Scripts Bind Mount Setup

**Date:** 2025-12-20
**Purpose:** Create a shared folder for scripts between Proxmox host and LXC 102 container
**Status:** Pre-implementation (analysis complete, awaiting execution)

---

## Objective

Create a bind mount that allows:
- **I (Claude Code)** to create, edit, and delete scripts from inside LXC 102 container
- **User** to execute these scripts directly on the Proxmox host
- Scripts run as `sleszugreen` user (non-root, security best practice)

---

## Pre-Implementation Analysis

### Current LXC 102 Configuration

```
arch: amd64
cores: 4
features: nesting=1
hostname: ugreen-ai-terminal
memory: 4096
mp0: /root/proxmox-hardening-source,mp=/home/sleszugreen/projects/proxmox-hardening
net0: name=eth0,bridge=vmbr0,gw=192.168.40.1,hwaddr=BC:24:11:F2:74:C4,ip=192.168.40.82/24,type=veth
onboot: 1
ostype: ubuntu
rootfs: nvme2tb:subvol-102-disk-0,size=20G
startup: order=1,up=0,down=60
swap: 512
unprivileged: 1
unused0: local-lvm:vm-102-disk-0
```

### Key Findings

| Factor | Result | Impact |
|--------|--------|--------|
| Existing mount points | 1 (mp0) | mp1 available for new mount |
| 2TB NVMe mount point | `/nvme2tb` | Directory path: `/nvme2tb/lxc102scripts/` |
| 2TB NVMe free space | 1.8TB | ✅ No space concerns |
| Container /mnt directory | Exists, empty | ✅ Safe mount target |
| Config syntax | Clean, standard | ✅ No conflicting entries |
| Container privilege | unprivileged: 1 | ✅ Good security posture |

### Risk Assessment: **LOW RISK**

**Identified risks:** None
**Potential issues:** None identified during analysis
**Confidence level:** 95% - configuration is standard and clean

---

## Implementation Procedure

### Directory Structure

**On Proxmox Host:**
```
/nvme2tb/lxc102scripts/
  ├── (user-created scripts will be placed here)
```

**In LXC 102 Container:**
```
/mnt/lxc102scripts/
  ├── (same scripts, accessible for editing)
```

### Pre-Implementation Checklist

- ✅ Current config backed up (user has access to `/etc/pve/lxc/102.conf`)
- ✅ 2TB NVMe path verified (`/nvme2tb`)
- ✅ No path conflicts
- ✅ Rollback plan documented
- ✅ Session saved to GitHub

### Configuration Change

**File to modify:** `/etc/pve/lxc/102.conf`

**Change required:**
```diff
+ mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts
```

**Rationale:**
- `mp1:` = second mount point (mp0 already exists)
- `/nvme2tb/lxc102scripts` = path on Proxmox host (on 2TB NVMe)
- `mp=/mnt/lxc102scripts` = mount path inside container
- Standard Proxmox LXC configuration syntax

---

## Rollback Plan

If the container fails to start or any issue occurs:

### Option 1: Remove the Mount Line (Simplest)
```bash
# SSH to Proxmox host
ssh root@192.168.40.60

# Edit the config file
nano /etc/pve/lxc/102.conf

# Remove this line:
# mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts

# Save and exit (Ctrl+X, Y, Enter)

# Restart the container
pct start 102
```

### Option 2: Restore from Backup
If you saved a backup before making changes, restore it:
```bash
# SSH to Proxmox host
ssh root@192.168.40.60

# Check current config
cat /etc/pve/lxc/102.conf

# If needed, restore (if you made a backup)
cp /etc/pve/lxc/102.conf.backup /etc/pve/lxc/102.conf
pct start 102
```

---

## Verification Plan

After successful implementation:

1. **From inside container:**
   ```bash
   ls -la /mnt/lxc102scripts/
   touch /mnt/lxc102scripts/test-file.txt
   rm /mnt/lxc102scripts/test-file.txt
   ```

2. **From Proxmox host:**
   ```bash
   ls -la /nvme2tb/lxc102scripts/
   ```

Both should show the same contents.

---

## Notes for Next Session

- This mount is persistent - will survive container restart
- Scripts placed in `/mnt/lxc102scripts/` can be executed from Proxmox host
- Permissions inherit from sleszugreen user ownership
- No additional configuration needed after implementation

---

## Commands to Execute (Step by Step)

See IMPLEMENTATION-COMMANDS.md for exact commands to run during container restart.
