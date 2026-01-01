# Phase A: Remote Access Foundation

**Status:** Scripts Ready for Execution
**Location:** `/root/proxmox-hardening/`
**Duration:** ~55 minutes

---

## ⚠️ CRITICAL PRIORITY

**Phase A must be completed BEFORE moving the UGREEN box to a remote location!**

This phase establishes and thoroughly tests remote access to ensure you won't get locked out when the box is moved away from monitor/keyboard access.

---

## Overview

Phase A prepares your Proxmox system for hardening by:

1. Fixing Proxmox repositories (removing "no subscription" popup)
2. Configuring accurate time synchronization
3. Creating backups of all critical configuration files
4. Setting up SMART disk health monitoring
5. **Establishing SSH key authentication (CRITICAL!)**
6. **Verifying all remote access methods work**

**You MUST complete Checkpoint #1 before proceeding to Phase B!**

---

## Prerequisites

Before starting Phase A:

- [ ] Physical access to UGREEN server (monitor + keyboard)
- [ ] SSH access from your desktop (192.168.99.6)
- [ ] Proxmox Web UI access: https://192.168.40.60:8006
- [ ] At least 2 SSH terminal sessions open
- [ ] User: sleszugreen with sudo access

---

## Phase A Scripts

Execute these scripts **in order** on the Proxmox host:

### Script 0: Repository Configuration
**File:** `00-repository-setup.sh`
**Duration:** ~5 minutes
**Purpose:** Fix Proxmox repos, enable free updates, remove subscription popup

```bash
sudo bash /root/proxmox-hardening/00-repository-setup.sh
```

**What it does:**
- Disables Enterprise repository (requires paid subscription)
- Enables no-subscription repository (free updates)
- Updates package lists
- Removes "no valid subscription" popup

**After completion:**
- Clear your browser cache
- Reload Proxmox Web UI
- Popup should be gone

---

### Script 1: Time Synchronization
**File:** `01-ntp-setup.sh`
**Duration:** ~3 minutes
**Purpose:** Configure NTP for accurate time (critical for SSL certs)

```bash
sudo bash /root/proxmox-hardening/01-ntp-setup.sh
```

**What it does:**
- Sets timezone to Europe/Warsaw
- Configures NTP servers (pool.ntp.org)
- Enables systemd-timesyncd
- Verifies time synchronization

**Verify:**
```bash
timedatectl status
```

---

### Script 2: Pre-Hardening Checks & Backups
**File:** `02-pre-hardening-checks.sh`
**Duration:** ~10 minutes
**Purpose:** Create safety backups and verify emergency access

```bash
sudo bash /root/proxmox-hardening/02-pre-hardening-checks.sh
```

**What it does:**
- Creates backup directory structure
- Backs up all critical config files:
  - SSH configuration
  - Firewall rules
  - Network configuration
  - Repository settings
- Creates package list snapshot
- Creates emergency rollback script
- Displays pre-flight safety checklist

**IMPORTANT:** This script creates the emergency rollback script at:
`/root/proxmox-hardening/99-emergency-rollback.sh`

Use this if you get locked out!

---

### Script 3: SMART Disk Monitoring
**File:** `03-smart-monitoring.sh`
**Duration:** ~10 minutes
**Purpose:** Set up disk health monitoring to prevent data loss

```bash
sudo bash /root/proxmox-hardening/03-smart-monitoring.sh
```

**What it does:**
- Installs smartmontools
- Detects all storage devices
- Enables SMART on capable disks
- Configures automatic self-tests:
  - Short test: Daily at 2 AM
  - Long test: Weekly on Saturday at 3 AM
- Sets up temperature monitoring
- Creates alert scripts (for ntfy.sh later)
- Enables smartd service

**Check disk health:**
```bash
sudo smart-status.sh
```

---

### Script 4: SSH Key Authentication Setup
**File:** `04-ssh-key-setup.sh`
**Duration:** ~15 minutes
**Purpose:** Set up SSH keys BEFORE disabling password auth

```bash
sudo bash /root/proxmox-hardening/04-ssh-key-setup.sh
```

**⚠️ CRITICAL SCRIPT - READ CAREFULLY!**

**What it does:**
- Provides detailed instructions for generating SSH keys on your desktop
- Prompts you to paste your public key
- Configures authorized_keys with correct permissions
- Adds emergency root access (temporary)
- Guides you through testing key authentication
- **Does NOT proceed until you confirm keys work!**

**You will need to:**

1. **On your desktop (192.168.99.6)**, generate SSH keys:
   ```bash
   # Recommended: Ed25519
   ssh-keygen -t ed25519 -C "sleszugreen@ugreen-proxmox"

   # Alternative: RSA
   ssh-keygen -t rsa -b 4096 -C "sleszugreen@ugreen-proxmox"
   ```

2. Display your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # OR
   cat ~/.ssh/id_rsa.pub
   ```

3. Copy the ENTIRE output (one long line)

4. Paste it when the script prompts you

5. **Test in a NEW terminal:**
   ```bash
   ssh sleszugreen@192.168.40.60
   ```

   Should login WITHOUT password!

**DO NOT CONTINUE until SSH key authentication works!**

---

### Script 5: Remote Access Test (Checkpoint #1)
**File:** `05-remote-access-test-1.sh`
**Duration:** ~10 minutes
**Purpose:** **MANDATORY CHECKPOINT** - Verify all remote access methods

```bash
sudo bash /root/proxmox-hardening/05-remote-access-test-1.sh
```

**⚠️ MANDATORY CHECKPOINT - DO NOT SKIP!**

This script verifies:

1. ✓ SSH key authentication works
2. ✓ Multiple SSH sessions can be opened
3. ✓ Proxmox Web UI is accessible
4. ✓ **Web UI Shell works (EMERGENCY BACKUP ACCESS!)**
5. ✓ Sudo access works
6. ✓ Network connectivity works
7. ✓ You understand emergency access methods

**Critical Tests:**
- **SSH keys must work**
- **Web UI must be accessible**
- **Web UI Shell must work** (this is your emergency backup!)

**If ANY critical test fails:**
- Script will STOP you from proceeding
- Fix the issue
- Re-run the checkpoint script
- **DO NOT proceed to Phase B until all tests pass!**

**Emergency Access via Web UI Shell:**
1. Open https://192.168.40.60:8006
2. Login with sleszugreen
3. Click on node name in left sidebar
4. Click "Shell" button (>_) at top
5. You have a terminal in your browser!

This is your backup if SSH fails!

---

## Phase A Completion Checklist

Before proceeding to Phase B, verify:

- [ ] Proxmox repositories configured (subscription popup gone)
- [ ] Time synchronization active (timedatectl shows NTP: active)
- [ ] Configuration backups created in `/root/proxmox-hardening/backups/`
- [ ] SMART monitoring active (smartd service running)
- [ ] SSH key authentication working from desktop
- [ ] **Checkpoint #1 script shows "PASSED"**
- [ ] At least 2 SSH sessions currently open
- [ ] Proxmox Web UI accessible and tested
- [ ] Web UI Shell tested and working
- [ ] Emergency rollback script created

---

## Estimated Time

| Script | Duration | Cumulative |
|--------|----------|------------|
| 00-repository-setup.sh | 5 min | 5 min |
| 01-ntp-setup.sh | 3 min | 8 min |
| 02-pre-hardening-checks.sh | 10 min | 18 min |
| 03-smart-monitoring.sh | 10 min | 28 min |
| 04-ssh-key-setup.sh | 15 min | 43 min |
| 05-remote-access-test-1.sh | 10 min | 53 min |
| **Total** | **~55 minutes** | |

*Times are estimates - take longer if needed to ensure everything works!*

---

## Troubleshooting

### SSH Key Authentication Not Working

**Check your public key:**
```bash
cat /home/sleszugreen/.ssh/authorized_keys
```

**Check permissions:**
```bash
ls -la /home/sleszugreen/.ssh/
ls -la /home/sleszugreen/.ssh/authorized_keys
```

Should be:
- `.ssh/` directory: `drwx------ (700)`
- `authorized_keys`: `-rw------- (600)`

**Fix permissions:**
```bash
sudo chmod 700 /home/sleszugreen/.ssh
sudo chmod 600 /home/sleszugreen/.ssh/authorized_keys
sudo chown -R sleszugreen:sleszugreen /home/sleszugreen/.ssh
```

**Check SSH logs:**
```bash
sudo tail -f /var/log/auth.log
```

Then try SSH again and watch for errors.

---

### Web UI Not Accessible

**Check pveproxy service:**
```bash
sudo systemctl status pveproxy
```

**Restart if needed:**
```bash
sudo systemctl restart pveproxy
```

**Check it's listening:**
```bash
sudo ss -tlnp | grep 8006
```

**Check firewall:**
```bash
sudo systemctl status pve-firewall
```

If firewall is active, temporarily disable:
```bash
sudo systemctl stop pve-firewall
```

---

### Emergency Rollback

If something goes wrong, run:

```bash
sudo bash /root/proxmox-hardening/99-emergency-rollback.sh
```

This will:
- Restore all backed-up configurations
- Disable firewall
- Restore SSH to defaults
- Reset to pre-hardening state

---

## Safety Reminders

⚠️ **ALWAYS keep at least 2 SSH sessions open**

⚠️ **Test each change before closing old sessions**

⚠️ **Web UI Shell is your emergency backup access**

⚠️ **Complete Checkpoint #1 before proceeding to Phase B**

⚠️ **Physical console access is the ultimate fallback**

---

## Next Steps

After Phase A is complete and Checkpoint #1 passes:

**Proceed to Phase B: Security Hardening**

Phase B will:
- Install security tools and updates
- Configure firewall (whitelist 192.168.99.6)
- Set up HTTPS certificate for Web UI
- Harden SSH (port 22022, keys-only, no root)
- Complete Checkpoint #2

**Read:** `README-PHASE-B.md` (will be created)

**Start with:** `sudo bash 06-system-update.sh`

---

## Important Files & Locations

| File/Directory | Purpose |
|---------------|---------|
| `/root/proxmox-hardening/` | Main script directory |
| `/root/proxmox-hardening/backups/` | Configuration backups |
| `/root/proxmox-hardening/hardening.log` | Execution log |
| `/root/proxmox-hardening/99-emergency-rollback.sh` | Emergency restore |
| `/home/sleszugreen/.ssh/authorized_keys` | Your SSH public keys |
| `/etc/smartd.conf` | SMART monitoring config |
| `/usr/local/bin/smart-status.sh` | Check disk health |

---

## Support

If you encounter issues:

1. Check the logs: `cat /root/proxmox-hardening/hardening.log`
2. Re-run the failed script (most are idempotent)
3. Use emergency rollback if needed
4. Access via Web UI Shell if SSH fails

---

**Last Updated:** 2025-12-09
**Proxmox Version:** 9.1.2
**Phase:** A - Remote Access Foundation
