# Phase B: Security Hardening - User Guide

**Status:** Phase A ✅ COMPLETE | Ready to begin Phase B

---

## Overview

Phase B hardens your Proxmox server security **BEFORE** moving it to a remote location.

**What Phase B Does:**
- Updates system and installs security tools
- Configures firewall to protect the system
- Hardens SSH (new port, keys-only authentication)
- Verifies all hardened access works

**⚠️ CRITICAL: Complete ALL Phase B scripts BEFORE moving the box!**

---

## Prerequisites

Before starting Phase B:
- ✅ Phase A complete (all scripts 00-05 executed)
- ✅ Checkpoint #1 passed (all remote access verified)
- ✅ Strong passwords set for root and sleszugreen
- ✅ SSH key authentication working
- ✅ Web UI access working

---

## Phase B Scripts

Execute these scripts **IN ORDER** on the Proxmox host (not LXC container):

### Script 06: System Updates & Security Tools
**File:** `/root/proxmox-hardening/06-system-updates.sh`
**Duration:** ~15-20 minutes
**Purpose:** Update system and install security packages

```bash
cd /root/proxmox-hardening
bash 06-system-updates.sh
```

**What it does:**
- Updates all system packages
- Installs fail2ban, unattended-upgrades, security tools
- Configures automatic security updates
- Sets auto-reboot time to 3:00 AM

**Note:** This may require a reboot if kernel is updated.

---

### Script 07: Firewall Configuration
**File:** `/root/proxmox-hardening/07-firewall-config.sh`
**Duration:** ~5 minutes
**Purpose:** Lock down network access to trusted IP only

```bash
bash 07-firewall-config.sh
```

**What it does:**
- Configures Proxmox native firewall
- Whitelists trusted desktop: 192.168.99.6
- Allows SSH (ports 22 and 22022)
- Allows Web UI (port 8006)
- Drops all other traffic

**⚠️ IMPORTANT:** Your current SSH session will NOT be killed!

**Safety:** Emergency disable command provided if needed

---

### Script 08: Proxmox Backup (OPTIONAL)
**File:** `/root/proxmox-hardening/08-proxmox-backup.sh`
**Duration:** ~5 minutes
**Purpose:** Create backup of Proxmox configuration

```bash
bash 08-proxmox-backup.sh
```

**What it does:**
- Backs up /etc/pve directory
- Backs up system configs
- Creates compressed archive
- Includes restoration instructions

**Note:** This script is OPTIONAL - you can skip it if you don't need a backup.

---

### Script 09: SSH Hardening ⚠️ CRITICAL
**File:** `/root/proxmox-hardening/09-ssh-hardening.sh`
**Duration:** ~10 minutes
**Purpose:** Harden SSH (change port, disable passwords)

```bash
bash 09-ssh-hardening.sh
```

**What it does:**
- Changes SSH port: 22 → 22022
- Disables password authentication (keys only!)
- Disables root password login
- Keeps root key login enabled

**⚠️ BEFORE RUNNING THIS SCRIPT:**

1. **Open 2-3 SSH sessions** (keep them all open!)
2. **Test SSH key authentication** one more time:
   ```cmd
   ssh -i C:\Users\jakub\.ssh\ugreen_key root@192.168.40.60
   ssh -i C:\Users\jakub\.ssh\ugreen_key sleszugreen@192.168.40.60
   ```
3. **Verify Web UI Shell** works (emergency backup access)
4. **DO NOT close any sessions** until Checkpoint #2 passes!

**After this script:**
- Old SSH command: `ssh root@192.168.40.60` → ❌ WON'T WORK
- New SSH command: `ssh -p 22022 root@192.168.40.60` → ✅ WORKS (with key)
- Password login: ❌ DISABLED (keys only)

---

### Script 10: Checkpoint #2 - Verify Hardened Access
**File:** `/root/proxmox-hardening/10-checkpoint-2.sh`
**Duration:** ~15 minutes
**Purpose:** Verify ALL hardening works correctly

```bash
bash 10-checkpoint-2.sh
```

**What it tests:**
1. SSH service running on new port (22022)
2. Password authentication disabled
3. Root SSH key authentication works
4. User SSH key authentication works
5. Firewall active and protecting system
6. Web UI accessible from trusted IP
7. Web UI Shell emergency access works
8. Multiple SSH sessions can connect
9. All security hardening applied correctly

**⚠️ THIS CHECKPOINT MUST PASS BEFORE MOVING THE BOX!**

If any test fails:
- DO NOT move the box yet
- Fix the failed test(s)
- Re-run the checkpoint

---

## Execution Checklist

Use this checklist to track your progress:

```
Phase B Scripts:
[  ] 06-system-updates.sh - System updated, security tools installed
[  ] 07-firewall-config.sh - Firewall configured and active
[  ] 08-proxmox-backup.sh - Backup created (OPTIONAL)
[  ] 09-ssh-hardening.sh - SSH hardened (port 22022, keys only)
[  ] 10-checkpoint-2.sh - ALL TESTS PASSED

Pre-Move Verification:
[  ] Can SSH on new port 22022 with key
[  ] Cannot SSH with password (correctly blocked)
[  ] Web UI accessible from desktop
[  ] Web UI Shell tested (emergency access)
[  ] Firewall active and protecting system
[  ] All passwords documented and secure
[  ] Emergency access methods verified
```

---

## Important Notes

### SSH After Hardening

**Old way (before Phase B):**
```cmd
ssh root@192.168.40.60
# Uses: port 22, password OR key
```

**New way (after Phase B):**
```cmd
ssh -i C:\Users\jakub\.ssh\ugreen_key -p 22022 root@192.168.40.60
# Uses: port 22022, KEY ONLY
```

### Desktop SSH Config (Optional)

You can create `~/.ssh/config` on your Windows desktop to simplify SSH:

```
Host ugreen
    HostName 192.168.40.60
    Port 22022
    User root
    IdentityFile C:\Users\jakub\.ssh\ugreen_key
```

Then you can just type: `ssh ugreen`

---

## Emergency Access Methods

If you get locked out, you have these backup access methods:

### 1. Web UI Shell (Primary Emergency Access)
1. Open browser: `https://192.168.40.60:8006`
2. Login as root@pam with password
3. Click node "ugreen"
4. Click ">_ Shell" button
5. Terminal opens in browser
6. You have root access!

### 2. Physical Console (If Available)
- Connect monitor and keyboard
- Login as root with password
- Fix SSH configuration

### 3. Emergency Restore Commands

**Disable firewall:**
```bash
systemctl stop pve-firewall
```

**Restore original SSH config:**
```bash
cp /root/proxmox-hardening/backups/ssh/sshd_config.before-hardening /etc/ssh/sshd_config
systemctl restart ssh
```

---

## After Phase B Completion

Once Checkpoint #2 passes:

✅ **Safe to move the box to remote location**

Your system is now:
- Hardened and secure
- Protected by firewall
- Accessible only via SSH keys
- Ready for deployment

**Next:** Phase C (Monitoring & Protection) - Can be done AFTER moving the box

---

## Troubleshooting

### Problem: Locked out of SSH after script 09

**Solution:**
1. Use Web UI Shell emergency access
2. Check SSH service: `systemctl status ssh`
3. Check SSH listening: `ss -tln | grep 22022`
4. Restore backup if needed: `cp /root/proxmox-hardening/backups/ssh/sshd_config.before-hardening /etc/ssh/sshd_config && systemctl restart ssh`

### Problem: Firewall blocking access

**Solution:**
1. Use Web UI Shell emergency access
2. Check firewall rules: `cat /etc/pve/firewall/cluster.fw`
3. Verify trusted IP is correct: 192.168.99.6
4. Temporarily disable: `systemctl stop pve-firewall`

### Problem: Can't access Web UI

**Solution:**
1. Check pveproxy service: `systemctl status pveproxy`
2. Restart if needed: `systemctl restart pveproxy`
3. Check firewall allows port 8006 from your IP
4. Try different browser or incognito mode

---

## Questions?

If you encounter issues:
1. DO NOT close your SSH sessions
2. Check the logs: `/root/proxmox-hardening/hardening.log`
3. Review error messages from the scripts
4. Use emergency access methods if needed

**Remember:** Each script has safety checks and confirmation prompts. Read them carefully before proceeding!

---

**Generated:** 2025-12-11
**Phase:** B - Security Hardening (BEFORE MOVING BOX)
