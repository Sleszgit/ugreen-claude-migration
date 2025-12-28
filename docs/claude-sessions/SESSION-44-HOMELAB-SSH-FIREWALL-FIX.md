# SESSION 44: Homelab SSH Firewall Fix & Passwordless Sudo Configuration

**Date:** 28 Dec 2025  
**Location:** UGREEN LXC 102  
**Status:** In Progress - Firewall fixed, configuring passwordless sudo  

---

## Problem
SSH from UGREEN LXC 102 (192.168.40.82) to homelab Proxmox (192.168.40.40) was blocked by malformed firewall config.

## Actions Completed

### 1. ✅ Firewall Configuration Fixed
- **Issue:** `/etc/pve/firewall/cluster.fw` had EOF marker in middle of file (broken heredoc)
- **Solution:** Created `/home/sleszugreen/scripts/fix-homelab-firewall-local.sh` 
- **Executed on homelab:** `sudo bash /home/sshadmin/fix-homelab-firewall-local.sh`
- **Result:** 
  - Backup created at: `/root/firewall-backups/cluster.fw.backup-20251228-052902`
  - Firewall service restarted successfully
  - SSH port 22 now accessible from UGREEN

### 2. ✅ SSH Connectivity Verified
- **As sshadmin user:** `ssh sshadmin@192.168.40.40` → **WORKS** ✅
- **As ugreen-homelab-ssh:** `ssh ugreen-homelab-ssh@192.168.40.40` → **WORKS** ✅
- **Passwordless sudo test:** `ssh ugreen-homelab-ssh@192.168.40.40 "sudo pveversion"` → **WORKS** ✅

### 3. ⏳ Sudoers Configuration - IN PROGRESS
- Created `/etc/sudoers.d/ugreen-homelab-ssh` but initial paths were incorrect
- Initial attempt used wrong paths (e.g., `/usr/bin/pct` instead of `/usr/sbin/pct`)
- **Correct paths identified:**
  - `/usr/bin/qm` - VM management
  - `/usr/sbin/pct` - Container management
  - `/usr/bin/pvesh` - Proxmox API CLI
  - `/usr/bin/pveum` - User/permission management
  - `/usr/sbin/zpool` - ZFS pool management
  - `/usr/sbin/zfs` - ZFS filesystem management
  - `/usr/bin/systemctl` - Service management
  - `/usr/sbin/pve-firewall` - Firewall service
  - `/usr/bin/pveversion` - Version info

## Current Firewall Config
**File:** `/etc/pve/firewall/cluster.fw` (on homelab)

**Key rules applied:**
```
IN ACCEPT -source +management -p tcp -dport 22 -log nolog
IN ACCEPT -source 192.168.40.82 -p tcp -dport 22 -log nolog  ← UGREEN LXC102
```

**IPSETs defined:**
```
[IPSET management]
100.64.0.0/10   # Tailscale network
192.168.40.0/24 # Proxmox local VLAN
192.168.99.0/24 # Desktop/Management VLAN
10.10.10.0/24   # Docker-Services VLAN
```

## Scripts Created on UGREEN

1. **`/home/sleszugreen/scripts/fix-homelab-firewall.sh`**
   - Initial version with remote SSH execution (abandoned due to TTY issues)

2. **`/home/sleszugreen/scripts/fix-homelab-firewall-local.sh`**
   - Works locally on homelab (used successfully)
   - Location: `/home/sshadmin/` on homelab for execution
   - Status: ✅ Successfully ran

3. **`/home/sleszugreen/scripts/setup-ugreen-sudo.sh`**
   - Created but not used (went with direct commands instead)

## Next Steps to Complete

### 1. Update Sudoers File (CRITICAL - NOT YET DONE)
Run on homelab as sshadmin:

```bash
sudo bash -c 'cat > /etc/sudoers.d/ugreen-homelab-ssh << "EOF"
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/qm
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/pct
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/pvesh
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/pveum
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/zpool
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/zfs
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/systemctl
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/sbin/pve-firewall
ugreen-homelab-ssh ALL=(ALL) NOPASSWD: /usr/bin/pveversion
EOF'
```

Then verify:
```bash
sudo visudo -c -f /etc/sudoers.d/ugreen-homelab-ssh
```

### 2. Test Full Passwordless Sudo Access from UGREEN
```bash
ssh ugreen-homelab-ssh@192.168.40.40 "sudo pveversion"
ssh ugreen-homelab-ssh@192.168.40.40 "sudo pct list"
ssh ugreen-homelab-ssh@192.168.40.40 "sudo qm list"
```

### 3. Update CLAUDE.md
Update homelab access status from "IN PROGRESS" to "✅ OPERATIONAL"

---

## Key Technical Notes

### Why Heredoc (`<< 'EOF'`) Doesn't Work
- Shell parsing error: "here-document delimited by end-of-file"
- Workaround: Use individual `echo` commands or `cat >` with bash -c wrapper
- **Note for future:** This is a system/shell configuration issue that needs investigation

### SSH Connection Flow
1. UGREEN LXC 102 → Homelab host (192.168.40.40)
2. Uses `/root/.ssh/id_ed25519` key
3. SSH config in `~/.ssh/config`:
```
Host homelab
    HostName 192.168.40.40
    User ugreen-homelab-ssh
    IdentityFile ~/.ssh/id_ed25519
```

### Sudoers Configuration Details
- File: `/etc/sudoers.d/ugreen-homelab-ssh`
- Permissions: `0440` (read-only for owner and group)
- User already in `sudo` group (has `(ALL : ALL) ALL` rule from default sudoers)
- NOPASSWD rules take precedence for listed commands

---

## Files & Locations

**On UGREEN LXC 102:**
- `/home/sleszugreen/scripts/fix-homelab-firewall-local.sh` - Firewall fix script
- `/home/sleszugreen/scripts/fix-homelab-firewall.sh` - Old remote version (abandoned)
- `/home/sleszugreen/scripts/setup-ugreen-sudo.sh` - Sudoers setup script (unused)
- `~/.ssh/config` - SSH config with homelab entry
- `~/.ssh/id_ed25519` - SSH private key used for authentication

**On Homelab:**
- `/etc/pve/firewall/cluster.fw` - Corrected firewall config ✅
- `/root/firewall-backups/cluster.fw.backup-20251228-052902` - Backup of broken config
- `/etc/sudoers.d/ugreen-homelab-ssh` - Sudoers file (NEEDS UPDATE with correct paths)
- `/etc/ssh/sshd_config` - SSH server config (updated to allow ugreen-homelab-ssh)
- `/home/ugreen-homelab-ssh/` - Dedicated user home directory

---

## Infrastructure Context

| System | IP | Role |
|--------|-----|------|
| UGREEN Proxmox Host | 192.168.40.60 | Hypervisor |
| UGREEN LXC 102 | 192.168.40.82 | Claude Code container (this instance) |
| Homelab Proxmox Host | 192.168.40.40 | Remote hypervisor (target) |
| Windows Desktop | 192.168.99.6 | Current fallback for homelab access |

---

## Session Goal Recap

Enable UGREEN Claude Code (LXC 102) to manage the homelab Proxmox host via SSH with the dedicated `ugreen-homelab-ssh` user account, eliminating the need to use Windows Desktop as an intermediary for homelab operations.

**Current Progress:** ~85% complete (firewall fixed, SSH works, sudoers in final stages)

---

## Lessons Learned

1. **Heredoc issues are system-specific** - The `<< 'EOF'` syntax consistently fails; use `cat >` with bash -c or individual echo commands
2. **Firewall file corruption silently breaks rules** - The EOF marker didn't prevent the file from being read, but rules after it were ignored
3. **Command paths vary by Proxmox version** - Always verify with `which` or `ls -l` before adding to sudoers
4. **Sudoers entries need individual lines** - Comma-separated paths in a single sudoers rule may not work as expected
5. **MobaXterm file transfer works better than heredoc** - For future scripting, prefer copying files via MobaXterm over SSH
