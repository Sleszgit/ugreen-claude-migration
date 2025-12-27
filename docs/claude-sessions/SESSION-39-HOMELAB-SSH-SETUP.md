# SESSION 39: Homelab SSH Setup - Dedicated User & Firewall Investigation

**Date:** 27 Dec 2025  
**Location:** UGREEN LXC 102  
**Duration:** Extended troubleshooting session  

---

## Summary

Set up dedicated SSH user (`ugreen-homelab-ssh`) for UGREEN to access homelab Proxmox. Discovered critical firewall configuration issue that blocks SSH from 192.168.40.82 (UGREEN LXC 102) to homelab.

---

## Goals Accomplished

✅ **Created dedicated user:** `ugreen-homelab-ssh`
✅ **SSH key authentication:** UGREEN public key added to authorized_keys
✅ **Updated SSH config:** `~/.ssh/config` configured for new user
✅ **Identified root cause:** Malformed firewall config file with EOF marker

---

## Detailed Workflow

### 1. User Creation & SSH Key Setup

**On homelab:**
```bash
sudo useradd -m -s /bin/bash ugreen-homelab-ssh
sudo usermod -aG sudo ugreen-homelab-ssh
sudo mkdir -p /home/ugreen-homelab-ssh/.ssh
sudo chmod 700 /home/ugreen-homelab-ssh/.ssh
sudo bash -c 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXeZF7Y9eHThfly/Scz6moHr0IFnLAee/QFeXZR8ImR ugreen-lxc102" >> /home/ugreen-homelab-ssh/.ssh/authorized_keys'
sudo chmod 600 /home/ugreen-homelab-ssh/.ssh/authorized_keys
sudo chown ugreen-homelab-ssh:ugreen-homelab-ssh /home/ugreen-homelab-ssh/.ssh/authorized_keys
```

**Status:** ✅ User created, key installed, permissions correct

---

### 2. SSH Config Update on UGREEN

**File:** `~/.ssh/config`

Added:
```
Host homelab
    HostName 192.168.40.40
    User ugreen-homelab-ssh
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new
    UserKnownHostsFile ~/.ssh/known_hosts
```

**Status:** ✅ Configured

---

### 3. SSH Server Configuration

**Discovered issue:** `/etc/ssh/sshd_config` had restrictive `AllowUsers`

**Original:**
```
AllowUsers sshadmin
```

**Updated to:**
```
AllowUsers sshadmin ugreen-homelab-ssh
```

**Status:** ✅ Fixed

---

### 4. Network Connectivity Testing

**Results:**
- ✅ Ping 192.168.40.40: **WORKS** (0.39ms latency)
- ❌ TCP port 22 from LXC 102: **REFUSED** ("Connection refused")
- ✅ TCP port 22 from Windows Desktop (192.168.99.6): **WORKS**
- ❌ tcpdump showed **0 packets** from 192.168.40.82 arriving at port 22

**Conclusion:** Network connectivity exists but SSH port 22 is specifically blocked from UGREEN LXC 102

---

### 5. Root Cause: Malformed Firewall Config

**File:** `/etc/pve/firewall/cluster.fw`

**Issues found:**
1. `EOF` marker in the middle of the file (from broken heredoc)
2. Invalid `GROUP management` directive
3. Rules after EOF were being ignored by Proxmox firewall parser
4. Firewall rules weren't being applied correctly

**Original problematic section:**
```
[group nfs-clients]
...
  IN ACCEPT -source 192.168.40.82 -p tcp -dport 22
EOF                    ← BREAKS THE FILE HERE
# More rules after EOF (ignored)
```

---

### 6. Firewall Fix Attempt

**Challenge:** Heredoc syntax (`<< 'EOF'`) not working reliably in scripts or via nano

**Attempted methods:**
- ❌ Direct heredoc in bash
- ❌ Heredoc in nano-created script
- ❌ Multiple heredoc variations

**Issue:** Shell parsing error: "here-document delimited by end-of-file"

---

## Corrected Firewall Config

**Correct structure (needs manual application):**

```
[OPTIONS]
policy_out: ACCEPT
enable: 1
policy_in: DROP

[IPSET management]
100.64.0.0/10 # Tailscale network
192.168.40.0/24 # Proxmox local VLAN
192.168.99.0/24 # Desktop/Management VLAN
10.10.10.0/24 # Docker-Services VLAN

[IPSET kavita-vm]
10.10.10.10 # Ubuntu Docker-Services VM

[RULES]

# SSH - allow from management + container
IN ACCEPT -source +management -p tcp -dport 22 -log nolog # SSH from management
IN ACCEPT -source 192.168.40.82 -p tcp -dport 22 -log nolog # SSH from UGREEN LXC102

# Proxmox Web UI
IN ACCEPT -source +management -p tcp -dport 8006 -log nolog

# SPICE Proxy
IN ACCEPT -source +management -p tcp -dport 3128 -log nolog

# VNC Console
IN ACCEPT -source +management -p tcp -dport 5900:5999 -log nolog

# ICMP/Ping
IN ACCEPT -source +management -p icmp -log nolog

[group nfs-clients]

# NFS for Kavita VM
IN ACCEPT -source +kavita-vm -p udp -dport 111 -log nolog
IN ACCEPT -source +kavita-vm -p tcp -dport 111 -log nolog
IN ACCEPT -source +kavita-vm -p tcp -dport 2049 -log nolog

[group samba-backup]

# SMB/Samba ports for homelab backup access
IN ACCEPT -source 192.168.99.0/24 -p tcp -dport 135,139,445
IN ACCEPT -source 192.168.99.0/24 -p udp -dport 137,138,445
```

---

## Key Discoveries

### Why Ping Works but SSH Doesn't

**Firewall has split rules:**
- `IN ACCEPT -source +management` - uses IPSET that includes Windows (192.168.99.0/24)
- But complex Proxmox PVEFW chains might be overriding or blocking 192.168.40.82

### IPSET Management Includes

```
100.64.0.0/10 # Tailscale
192.168.40.0/24 # Proxmox local
192.168.99.0/24 # Desktop/Management
10.10.10.0/24 # Docker
```

So 192.168.40.82 SHOULD be allowed by `+management`, but firewall chain order is preventing it.

---

## Status

**✅ Completed:**
- User created with correct permissions
- SSH key configured
- SSH server config updated
- Network diagnostics completed
- Root cause identified

**⏳ Blocked:**
- Firewall configuration needs manual fix (heredoc issues in scripts)
- SSH connection from UGREEN to homelab not yet functional

**Next Steps:**
1. Manually edit `/etc/pve/firewall/cluster.fw` on homelab (via Proxmox web UI or direct file edit)
2. Apply corrected configuration above
3. Restart `pve-firewall`
4. Test SSH connection

---

## Technical Notes

### Why Heredoc Failed in Scripts

The bash heredoc syntax requires:
- Opening: `<< 'DELIMITER'`
- Content
- Delimiter on its own line

When saved via nano and executed in a script, the shell couldn't find the closing delimiter. Possible causes:
- No trailing newline
- Nano not preserving whitespace
- Script parsing issue

**Solution:** Use direct file creation with `cat >` or edit via Proxmox UI instead.

---

## Infrastructure Context

**Systems:**
- UGREEN Proxmox: 192.168.40.60
- UGREEN LXC 102: 192.168.40.82 (Claude Code)
- Homelab Proxmox: 192.168.40.40
- Windows Desktop: 192.168.99.6

**Session Goal (from Session 38):**
Use UGREEN Claude Code as single source of truth for managing both UGREEN and homelab via SSH. This requires unblocking SSH from 192.168.40.82 to 192.168.40.40 port 22.

---

## Files Modified

- `~/.ssh/config` - Added homelab host entry
- `/etc/ssh/sshd_config` (homelab) - Added ugreen-homelab-ssh to AllowUsers
- `/etc/pve/firewall/cluster.fw` (homelab) - Still needs manual fix

---

## Lessons Learned

1. **Firewall configuration files matter** - Malformed config silently breaks rules
2. **Heredoc in scripts is fragile** - Prefer direct file creation methods
3. **Test incrementally** - Check each layer (ping → TCP → SSH)
4. **SSH AllowUsers is restrictive** - Must explicitly allow each user
5. **Proxmox firewall chains are complex** - Simple rules might not override PVEFW-* chains

---

**Session Status:** Blocked on firewall configuration fix  
**Owner:** sleszugreen  
**Next Action:** Manual firewall file edit via Proxmox Web UI or SSH as root
