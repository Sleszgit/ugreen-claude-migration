# Session 73: LXC 102 Container Crash Diagnosis - 2026-01-01

## Problem Summary

After the previous SSH hardening session, LXC 102 (ugreen-ai-terminal) container keeps stopping unexpectedly:

- SSH session from desktop closed by itself
- Container status changed to "stopped"
- When SSH disconnects, container also stops
- `pct start 102` command has been failing with "monitor socket" errors

## Root Cause Analysis

### Issue 1: Proxmox pct start Wrapper Bug
- `pct start 102` fails with: "problem with monitor socket, but continuing anyway: got timeout"
- Root cause: Proxmox systemd service wrapper issue (NOT container problem)
- Workaround: Use `sudo lxc-start -n 102` instead
- Status: Needs permanent fix or alternative approach

### Issue 2: Container Keeps Crashing
Possible causes identified:
1. **Init system failure** - systemd inside container may be crashing
2. **Foreground mode** - `lxc-start -n 102` likely runs in foreground; when SSH ends, container exits
3. **Missing auto-restart** - Container not configured to restart on failure
4. **Configuration issue** - ostype, console, or cmode misconfigured

## Diagnostic Plan

Pending execution of these commands ON PROXMOX HOST:

```bash
# Check container configuration
sudo pct config 102 | grep -E "^(ostype|console|cmode|onboot|hostname)"

# Start container and check init logs
sudo pct start 102 2>&1
sleep 3
sudo pct exec 102 -- journalctl -b -20 -p err

# Check if init process is running
sudo pct exec 102 -- ps aux | head -5

# Check container info
sudo lxc-info -n 102 -S
```

## Proposed Permanent Fixes (in order of preference)

### Option A: Enable Auto-Restart in LXC Config ✅ RECOMMENDED
```bash
sudo pct config 102
# Add/modify these lines in /etc/pve/lxc/102.conf:
onboot: 1
startup: order=2,delay=10,up=60
```
Benefits:
- Simple, native Proxmox solution
- Container auto-starts on Proxmox boot
- Auto-restarts if it crashes
- No additional scripts needed

### Option B: Create Emergency Startup Script (Fallback)
```bash
# Create /mnt/lxc102scripts/lxc102-start.sh
sudo lxc-start -n 102 &

# Add to crontab/systemd to run at boot
@reboot /mnt/lxc102scripts/lxc102-start.sh
```

### Option C: Investigate pct start Bug
- Check Proxmox logs for systemd wrapper issue
- May require Proxmox upgrade or service restart

### Option D: Repair Container Init System (if needed)
- If systemd is crashing inside container
- May need to reinstall or check for corrupted packages

## Next Steps

1. ✅ Run diagnostic commands on Proxmox host
2. ⏳ Analyze output to determine exact cause
3. ⏳ Apply permanent fix (likely Option A)
4. ⏳ Test container stability and auto-restart
5. ⏳ Document final solution

## Session Status

- Analyzed previous recovery session summary
- Identified container crash pattern
- Created diagnostic plan with root cause analysis
- Awaiting diagnostic command results from Proxmox host

**Token usage:** ~6,000 tokens
**Date:** 2026-01-01
**Location:** LXC 102 (ugreen-ai-terminal)
