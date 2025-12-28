# Session 45: Homelab SSH Completion - Passwordless Sudo Configuration

**Date:** 28 December 2025
**Status:** ✅ COMPLETED
**Duration:** ~45 minutes
**Objective:** Complete homelab SSH setup by configuring passwordless sudo for ugreen-homelab-ssh user

---

## Problem Statement

Session 44 left the homelab SSH setup 85% complete:
- ✅ SSH connectivity working (firewall fixed)
- ⏳ Sudoers file incomplete with incorrect command paths

The sudoers file needed to be updated with correct paths for Proxmox commands before UGREEN could execute remote administrative tasks.

---

## Key Technical Discovery: EOF Delimiter Issue

**Problem:** Heredoc syntax was failing with "here-document delimited by end-of-file" error

```bash
# ❌ FAILED - Heredoc breaks with sudo bash -c
sudo bash -c 'cat > /etc/sudoers.d/file << "EOF"
content
EOF'
```

**Solution:** Use individual `echo` commands instead of heredoc

```bash
# ✅ WORKS - Echo commands avoid heredoc parsing
sudo bash -c '
echo "line1" > /file
echo "line2" >> /file
echo "line3" >> /file
'
```

**Why This Works:**
- Avoids shell parsing complexity of nested quotes with heredoc
- Each echo is a simple, self-contained command
- No EOF delimiter confusion between bash and sudo layers
- First line uses `>`, subsequent lines use `>>`

---

## Actions Completed

### 1. Initial Sudoers Configuration (with wrong paths)

Created `/etc/sudoers.d/ugreen-homelab-ssh` using echo commands:
- Contained 9 sudoers entries for Proxmox commands
- Issue: Initial `/usr/bin/qm` path was incorrect

### 2. Path Discovery and Correction

Discovered actual command locations on homelab:
```
qm          → /usr/sbin/qm        (NOT /usr/bin/qm)
pct         → /usr/sbin/pct       (confirmed)
pvesh       → /usr/bin/pvesh      (confirmed)
pveum       → /usr/bin/pveum      (confirmed)
zpool       → /usr/sbin/zpool     (NOT /sbin/zpool)
zfs         → /usr/sbin/zfs       (NOT /sbin/zfs)
systemctl   → /usr/bin/systemctl  (confirmed)
pve-firewall → /usr/sbin/pve-firewall (confirmed)
pveversion  → /usr/bin/pveversion (confirmed)
```

### 3. Final Sudoers File Installation

**Sudoers entries created:**
```
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/qm
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/pct
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/pvesh
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/pveum
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/zpool
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/zfs
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/systemctl
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/pve-firewall
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/pveversion
```

### 4. Verification - All Commands Tested from UGREEN

```bash
ssh ugreen-homelab-ssh@192.168.40.40 "sudo pveversion"
# pve-manager/9.0.3/025864202ebb6109 (running kernel: 6.14.8-3-bpo12-pve)
# ✅ WORKS

ssh ugreen-homelab-ssh@192.168.40.40 "sudo qm list"
# VMID NAME            STATUS    MEM(MB)  BOOTDISK(GB)
# 100  docker-services running  32768    120.00
# ✅ WORKS

ssh ugreen-homelab-ssh@192.168.40.40 "sudo pct list"
# VMID Status Lock Name
# 101  running      immich
# 102  running      ai-terminal
# 200  running      netbox
# ✅ WORKS

ssh ugreen-homelab-ssh@192.168.40.40 "sudo zpool list"
# NAME   SIZE ALLOC  FREE  CAP HEALTH ALTROOT
# WD10TB 9.09T 4.31T 4.78T 47% ONLINE -
# ✅ WORKS
```

---

## Configuration Summary

### SSH Access Details
- **Source:** UGREEN LXC 102 (192.168.40.82)
- **Target:** Homelab Proxmox host (192.168.40.40)
- **User:** ugreen-homelab-ssh
- **Auth:** SSH key (/root/.ssh/id_ed25519)
- **Sudo:** Passwordless for 9 Proxmox commands

### Files Modified
- **Firewall (Session 44):** `/etc/pve/firewall/cluster.fw`
- **Sudoers (This session):** `/etc/sudoers.d/ugreen-homelab-ssh`
- **SSH Config:** `~/.ssh/config` (host entry exists)

### Homelab Infrastructure Discovered
| VM/Container | VMID | Type      | Status  | Memory |
|--------------|------|-----------|---------|--------|
| docker-services | 100 | VM        | Running | 32 GB  |
| immich       | 101  | Container | Running | -      |
| ai-terminal  | 102  | Container | Running | -      |
| netbox       | 200  | Container | Running | -      |

Storage: WD10TB ZFS pool (9.09 TB total, 4.31 TB used, 47% capacity)

---

## Documentation Updates

Updated `/home/sleszugreen/.claude/CLAUDE.md`:
- Changed homelab SSH status from "IN PROGRESS" to "✅ OPERATIONAL"
- Added list of available commands via SSH
- Updated date to 28 Dec 2025
- Added reference to this session document

---

## Impact & Next Steps

### What's Now Possible
✅ Query homelab VMs and containers from UGREEN
✅ Start/stop homelab VMs via SSH
✅ Create/delete VMs and containers remotely
✅ Manage ZFS pools and filesystems
✅ Monitor homelab Proxmox version and status
✅ Manage firewall rules remotely

### No Longer Needed
❌ Windows Desktop (192.168.99.6) as SSH intermediary
❌ Manual console access for basic operations

### What Still Needed
- Proxmox API token setup for homelab (if API access preferred over SSH)
- Documentation of common remote management tasks
- Monitoring/alerting integration

---

## Technical Lessons Learned

1. **Heredoc Parsing with sudo bash -c:** Avoid entirely - use echo commands
2. **Path Discovery:** Proxmox tools are split between /usr/bin/ and /usr/sbin/
   - VMs (/usr/bin/qm), Containers (/usr/sbin/pct)
   - Storage tools in /usr/sbin/ (zpool, zfs, pve-firewall)
3. **Sudoers Verification:** `visudo -c -f` still validates even with confusing error output
4. **SSH without TTY:** Interactive sudo doesn't work - need passwordless entries or scripts

---

## Files & References

**UGREEN Location:** LXC 102 (192.168.40.82)
**Homelab Location:** Proxmox host (192.168.40.40)

**Related Sessions:**
- Session 44: Firewall fix
- Session 39: Initial SSH setup
- Session 29: Proxmox API ACL fix

**Documentation:**
- `~/.claude/CLAUDE.md` - Main configuration
- `~/docs/claude-sessions/SESSION-44-*.md` - Firewall setup

---

**Session Status:** ✅ COMPLETE
**Outcome:** Homelab SSH with passwordless sudo is fully operational
**Ready for:** Remote VM/container management from UGREEN LXC 102
