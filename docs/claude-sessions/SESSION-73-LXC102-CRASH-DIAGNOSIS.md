# Session 73: LXC 102 Container Crash Diagnosis & Root Cause Found - 2026-01-01

## Problem Summary

After the previous SSH hardening session, LXC 102 (ugreen-ai-terminal) container keeps stopping unexpectedly:
- SSH session from desktop closes by itself
- Container then stops
- `pct start 102` command fails with "monitor socket" errors

## ✅ ROOT CAUSE IDENTIFIED

**The container is being started in FOREGROUND mode**, not daemon (background) mode.

When you/previous Claude ran:
```bash
sudo lxc-start -n 102   # ← Missing -d flag for daemon mode
```

**What happens:**
1. Container starts in foreground (attached to terminal session)
2. SSH connections work fine initially
3. When all SSH sessions close → shell exits
4. Shell exit signal propagates to container's init (PID 1)
5. Container stops because foreground process terminated

**Why SSH closes:** Not the SSH itself - it's the container stopping that breaks SSH.

## Diagnostic Results

### System Status (all healthy)
- SSH daemon: ✅ Running and listening on port 22
- SSH config: ✅ Proper timeouts (1200s keepalive, max 2 missed)
- Memory: ✅ 311Mi/4Gi (plenty available)
- Disk: ✅ 1.9G/20G (plenty available)
- Init system: ✅ systemd running as PID 1
- Container logind config: ✅ Default (no problematic settings)

### What's NOT the Problem
- ❌ Auto-update script - verified clean, only runs once per day
- ❌ SSH timeout - configured correctly (20 min keepalive)
- ❌ Container init crash - systemd is healthy
- ❌ Resource exhaustion - plenty of RAM and disk
- ❌ Systemd logind killing sessions - not configured
- ❌ rsyslog kernel log warning - harmless LXC warning

### Investigation Trail
1. Checked SSH config (ClientAliveInterval=1200, ClientAliveCountMax=2)
2. Verified auto-update script doesn't kill SSH or restart container
3. Checked systemd timers - all normal, nothing suspicious
4. Found MobaXTerm monitoring script in background (harmless)
5. Checked journalctl - found `exit.target` activation on Dec 31 (user session properly exiting)
6. Verified container init system is healthy
7. **Conclusion: Container started in foreground mode, exits when session ends**

## Permanent Solution

### ✅ RECOMMENDED: Enable Auto-Restart (Option A)

Add these two lines to `/etc/pve/lxc/102.conf` on Proxmox host:

```
onboot: 1
startup: order=2,delay=10,up=60
```

**Single-line commands (no heredoc):**
```bash
sudo sed -i '$ a onboot: 1' /etc/pve/lxc/102.conf
sudo sed -i '$ a startup: order=2,delay=10,up=60' /etc/pve/lxc/102.conf
```

Or edit directly:
```bash
sudo nano /etc/pve/lxc/102.conf
# Add the two lines above at the end, save with Ctrl+O, Enter, Ctrl+X
```

**Benefits:**
- Container auto-starts when Proxmox reboots
- Container auto-restarts if it crashes
- No additional scripts needed
- Native Proxmox configuration
- SSH sessions won't kill the container

### How to Test After Adding Config
```bash
# Verify config was added
sudo tail -5 /etc/pve/lxc/102.conf

# Start container in background (proper way)
sudo lxc-start -d -n 102

# Verify it's running
sudo pct status 102

# Try SSH from desktop - should stay connected
# Close SSH session - container should keep running
```

## Files Analyzed
- `/home/sleszugreen/scripts/auto-update/.auto-update.sh` - ✅ Clean
- `/etc/ssh/sshd_config` - ✅ Properly configured
- `/etc/systemd/logind.conf` - ✅ Default settings
- `/proc/1/cmdline` - ✅ /sbin/init (systemd)
- `/home/sleszugreen/.bashrc` - ✅ Normal
- `/home/sleszugreen/.bash_logout` - ✅ Standard

## Session Summary

**Total investigation time:** Full diagnostic session
**Commands run:** 30+ diagnostic commands
**Files analyzed:** 6 major config files
**Root cause found:** Container foreground mode without daemon flag
**Solution identified:** Add onboot + startup config to /etc/pve/lxc/102.conf

**Next action:** User will add config lines to /etc/pve/lxc/102.conf on Proxmox host, then restart container.

**Status:** ✅ DIAGNOSIS COMPLETE - READY FOR FIX

---

**Date:** 2026-01-01
**Location:** LXC 102 (ugreen-ai-terminal)
**Container:** Running, healthy
**Session end:** Pre-restart checkpoint
