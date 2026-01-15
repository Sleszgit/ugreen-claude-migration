# Session 129: SSH Hardening - Systemd Socket Activation Mystery

**Date:** 15 Jan 2026
**Status:** In Progress - Root Cause Identified, Fix Not Yet Complete
**Focus:** VM100 SSH hardening Script 01 - Port binding failure

---

## Summary

Continued work on VM100 SSH hardening from Sessions 125-128. Made significant progress:
- ✅ Fixed 3 critical script bugs (backup dir, empty keys check, temp file permissions)
- ✅ Identified root cause of SSH port binding failure (systemd socket activation)
- ✅ Added systemctl daemon-reload to fix socket binding
- ❌ **Port 22022 STILL NOT BINDING** despite all fixes

---

## Critical Issues Identified & Fixed

### Issue #1: Missing Backup Directory Creation
**Problem:** Script failed at Step 2 trying to create backup in non-existent directory
```
cp: cannot create regular file '/home/sleszugreen/vm100-hardening/backups/sshd_config.backup': No such file or directory
```

**Fix Applied:**
```bash
mkdir -p "$BACKUP_DIR" || { echo "FATAL: Cannot create backup directory"; exit 1; }
```

**Status:** ✅ FIXED

---

### Issue #2: Empty authorized_keys Not Detected
**Problem:** Script checked if file EXISTS but not if it HAD KEYS
- Previous behavior: Script reported "✓ authorized_keys found (0 key(s))" and continued
- Result: SSH hardened with zero valid keys, locking user out

**Fix Applied:**
```bash
KEYCOUNT=$(wc -l < ~/.ssh/authorized_keys)
if [[ "$KEYCOUNT" -eq 0 ]]; then
    echo "ERROR: Cannot harden SSH with zero authorized keys!"
    echo "Add at least one SSH key first"
    exit 1
fi
```

**Status:** ✅ FIXED - Script now rejects empty authorized_keys

---

### Issue #3: /tmp File Permissions
**Problem:** `/tmp/sshd_hardening` file creation failed with Permission Denied
```
/mnt/lxc102scripts/01-ssh-hardening.sh: line 79: /tmp/sshd_hardening: Permission denied
```

**Root Cause:** /tmp has restrictive permissions on this VM

**Fix Applied:**
```bash
SSHD_CONFIG_TMP=$(mktemp) || { echo "FATAL: Cannot create temp file"; exit 1; }
trap "rm -f '$SSHD_CONFIG_TMP'" EXIT
cat > "$SSHD_CONFIG_TMP" << 'EOF'
```

**Status:** ✅ FIXED - Now uses mktemp with proper cleanup

---

### Issue #4: Systemd Socket Activation (ROOT CAUSE IDENTIFIED)
**Problem:** SSH daemon not binding to port 22022 despite correct config

**Evidence:**
```
cat /etc/ssh/sshd_config | head -20
...
Include /etc/ssh/sshd_config.d/*.conf

# When systemd socket activation is used (the default), the socket
# configuration must be re-generated after changing Port, AddressFamily, or
# ListenAddress.
#
# For changes to take effect, run:
#
#   systemctl daemon-reload
```

**Root Cause:** Ubuntu 24.04 uses systemd socket activation by default. The systemd service pre-binds the socket to port 22. When we change Port in sshd_config, the socket doesn't automatically rebind - we need `systemctl daemon-reload`.

**Fix Applied:**
```bash
# Step 4.8: Reload systemd socket configuration
echo -e "${YELLOW}[STEP 4.8]${NC} Reloading systemd socket configuration..."
sudo systemctl daemon-reload || { echo -e "${RED}✗ Failed to reload systemd${NC}"; exit 1; }
echo -e "${GREEN}✓ Systemd socket configuration reloaded${NC}"
```

**Status:** ✅ FIX ADDED TO SCRIPT - But **still not working**

---

## Current Mystery: Port 22022 Not Binding

**Latest Test Output (with systemctl daemon-reload added):**
```
[STEP 4.8] Reloading systemd socket configuration...
✓ Systemd socket configuration reloaded

[STEP 5] Restarting SSH daemon...
✓ SSH daemon restarted

[STEP 6] Verifying SSH daemon binding...
✗ SSH NOT listening on port 22022
```

**Verified Facts:**
```bash
# sshd_config is correct
grep Port /etc/ssh/sshd_config
Port 22022

# But ss shows port 22, not 22022
sudo ss -tulnp | grep sshd
tcp   LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*
```

**What We Know:**
1. ✅ sshd_config syntax is valid (`sshd -t` passes)
2. ✅ UFW rule is in place (position 1)
3. ✅ systemctl daemon-reload ran successfully
4. ✅ systemctl restart ssh ran successfully
5. ❌ sshd is still listening on port 22, NOT port 22022
6. ❌ ss shows NO listening socket on port 22022

---

## Hypotheses for Port 22022 Not Binding

1. **Systemd Service Unit Issue**
   - Maybe sshd.service has a hardcoded port 22
   - Maybe socket activation is overriding the Port setting
   - Solution: Check `systemctl cat ssh` to see service unit config

2. **Include Directive Problem**
   - Script replaces sshd_config completely, removing `Include /etc/ssh/sshd_config.d/*.conf`
   - `/etc/ssh/sshd_config.d/50-cloud-init.conf` contains `PasswordAuthentication yes`
   - Maybe the Include directive is needed for other configs?
   - Solution: Keep the Include directive in sshd_config

3. **Systemd Socket Override**
   - Even though we daemon-reload, socket activation might be completely overriding Port setting
   - Need to disable socket activation or configure it differently
   - Solution: Check `systemctl status ssh.socket`

4. **SSH Service Configuration**
   - Cloud-init or other system might be resetting the config
   - Solution: Check if cloud-init is interfering

---

## Session Checkpoint

**Files Modified:**
- `/mnt/lxc102scripts/01-ssh-hardening.sh` - Added 4 critical fixes

**Key Learnings:**
1. Modern Ubuntu (24.04) uses systemd socket activation by default
2. Changing Port requires both config change AND `systemctl daemon-reload`
3. Even with daemon-reload, port binding still not working
4. Need deeper investigation into systemd socket/service configuration

**Next Steps (Session 130):**
1. Check systemd service unit configuration: `systemctl cat ssh`
2. Check systemd socket configuration: `systemctl status ssh.socket`
3. Investigate if sshd_config.d includes are essential
4. Consider whether socket activation needs to be disabled for port changes to work
5. Consult Gemini on systemd socket activation troubleshooting

**Test Procedure When Fixed:**
```bash
bash /mnt/lxc102scripts/01-ssh-hardening.sh
# Verify: sudo ss -tulnp | grep 22022
# Connect: ssh -p 22022 ubuntu-docker@10.10.10.100
```

---

## Related Sessions

- **Session 125:** VM100 hardening initial work
- **Session 126:** SSH binding mystery first diagnosis
- **Session 127:** UFW rule priority fix
- **Session 128:** Previous attempt with mktemp fix
- **Session 129:** Current - systemd socket activation fix attempt

---

**End of Session 129 Checkpoint**
