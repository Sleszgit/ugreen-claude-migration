# Session 130: SSH Hardening - Manual Implementation Complete

**Date:** 16 Jan 2026
**Status:** ✅ COMPLETE
**Focus:** VM100 SSH Hardening (Script 01) - Manual Execution

---

## Summary

After 4 sessions of script debugging (Sessions 125-129), the automated hardening script was abandoned per Gemini's recommendation. **Manual SSH hardening was executed successfully on VM100**, completing the task cleanly and reliably.

- ✅ SSH now listening on port 22022 only (hardened)
- ✅ Key-based authentication required (passwords disabled)
- ✅ Root login disabled
- ✅ Connectivity verified from LXC 102

---

## Root Cause Analysis: Script Failure

**Session 129 Issue:** Script Step 4 validation was failing with empty error output.

**Root Cause (per Gemini):**
- `sshd -t` returns **empty output on success** (no error message)
- Script validation logic incorrectly interpreted empty output as failure
- The script comparison `if sshd -t 2>&1 | grep -v "..."` was treating success as failure
- This was a logic error, not a configuration problem

**Decision:** Manual execution eliminated the script debugging loop entirely.

---

## Manual Implementation Steps (Executed)

### Step 1: Backup Original Config
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.manual
```
✅ Backup created at `/etc/ssh/sshd_config.bak.manual`

### Step 2: Edit sshd_config
```bash
sudo nano /etc/ssh/sshd_config
```

**Final Configuration:**
```ssh
# SSH Hardening Configuration - Manual
# Strategy: Dual Ports (22 + 22022) for safety during migration
Port 22
Port 22022

# Authentication Security
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no

# Session Security
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2

# Cleanup
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
```

✅ Config syntax validated: `sudo sshd -t` (silent success)

### Step 3: Firewall & Systemd
```bash
sudo ufw allow 22022/tcp comment 'SSH Custom Port'
sudo rm -f /etc/systemd/system/ssh.socket.d/listen.conf
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
sudo systemctl restart ssh
```

✅ UFW rule added (IPv4 + IPv6)
✅ Manual socket overrides removed (sshd-socket-generator handles it)

### Step 4: Initial Verification (Dual Ports)
```bash
sudo ss -tulnp | grep ssh
```

**Result:**
```
0.0.0.0:22    LISTEN (IPv4)
0.0.0.0:22022 LISTEN (IPv4)
[::]:22       LISTEN (IPv6)
[::]:22022    LISTEN (IPv6)
```

✅ Both ports bound successfully

### Step 5: Key Authentication Issue

**Problem:** SSH from LXC 102 failed with "Permission denied (publickey)"

**Root Cause:** LXC 102's ed25519 key was not in VM100's authorized_keys

**Solution:** Added LXC 102 ed25519 key:
```bash
ssh -p 22 sleszugreen@10.10.10.100 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXeZF7Y9eHThfly/Scz6moHr0IFnLAee/QFeXZR8ImR ugreen-lxc102" >> ~/.ssh/authorized_keys'
```

✅ Key added successfully

### Step 6: Test Both Ports (Dual Strategy)
```bash
ssh -i ~/.ssh/id_ed25519 -p 22 sleszugreen@10.10.10.100    # ✅ Connected
ssh -i ~/.ssh/id_ed25519 -p 22022 sleszugreen@10.10.10.100 # ✅ Connected
```

✅ Both ports working with key authentication

### Step 7: Remove Port 22 (Final Hardening)
```bash
sudo nano /etc/ssh/sshd_config
# Deleted: Port 22
# Kept: Port 22022

sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
sudo systemctl restart ssh
```

### Step 8: Final Verification (Single Port)
```bash
sudo ss -tulnp | grep ssh
```

**Result:**
```
0.0.0.0:22022 LISTEN (IPv4)
[::]:22022    LISTEN (IPv6)
```

✅ Port 22 removed, only 22022 listening

### Step 9: Final Connectivity Test
```bash
ssh -i ~/.ssh/id_ed25519 -p 22022 sleszugreen@10.10.10.100
# Last login: Fri Jan 16 04:49:13 2026 from 192.168.40.82
```

✅ **Connection successful** - SSH Hardening Complete

---

## Final Configuration Summary

| Setting | Value | Status |
|---------|-------|--------|
| **SSH Port** | 22022 only | ✅ |
| **Authentication** | Key-based (ed25519, rsa) | ✅ |
| **Password Auth** | Disabled | ✅ |
| **Root Login** | Disabled | ✅ |
| **Max Auth Tries** | 3 | ✅ |
| **Max Sessions** | 5 | ✅ |
| **X11Forwarding** | No | ✅ |
| **IPv4 Binding** | 0.0.0.0:22022 | ✅ |
| **IPv6 Binding** | [::]:22022 | ✅ |

---

## Lessons Learned

### What Worked
1. **Manual execution** - Immediate feedback, no script logic errors
2. **Dual-port strategy** - Safe testing before removing port 22
3. **sshd-socket-generator** - Correctly reads multiple Port directives (no manual socket overrides needed)
4. **Incremental testing** - Test each port before removing the fallback

### What Failed
1. **Automated script** - Validation logic misinterpreted empty success output as failure
2. **Manual socket overrides** - Created duplicate bindings with sshd-socket-generator
3. **sudo home expansion** - Initial script didn't detect $SUDO_USER properly (fixed in Step 1)

### Ubuntu 24.04 Specifics
- Uses **sshd-socket-generator** to auto-create socket bindings from sshd_config
- Multiple `Port` directives are properly supported
- No manual `/etc/systemd/system/ssh.socket.d/` overrides needed
- `systemctl daemon-reload` regenerates socket bindings

---

## Files & Backups

| Path | Purpose |
|------|---------|
| `/etc/ssh/sshd_config` | Active hardened config (Port 22022 only) |
| `/etc/ssh/sshd_config.bak.manual` | Backup before hardening |
| `/root/vm100-hardening/backups/sshd_config.backup` | Script-generated backup (from earlier attempts) |

---

## Next Steps

**Script 02 onwards** (in future sessions):
1. Firewall hardening
2. UFW rules refinement
3. System updates
4. Additional security configurations

---

## Related Sessions

- **Session 125:** VM100 hardening initial work
- **Session 126:** SSH binding mystery first diagnosis
- **Session 127:** UFW rule priority fix
- **Session 128:** Previous attempt with mktemp fix
- **Session 129:** Systemd socket activation investigation
- **Session 130:** ✅ Manual implementation - COMPLETE

---

**End of Session 130**

✅ SSH Hardening Script 01 COMPLETE
