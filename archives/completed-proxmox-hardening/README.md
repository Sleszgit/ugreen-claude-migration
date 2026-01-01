# Proxmox Security Hardening - UGREEN DXP4800+

**Target System:** UGREEN DXP4800+ Proxmox Host (192.168.40.60)
**Proxmox Version:** 9.1.2
**OS:** Debian GNU/Linux 13 (Trixie)
**Date Created:** 2025-12-08

---

## Overview

Comprehensive security hardening plan for Proxmox VE installation before moving the physical server to a remote location without monitor/keyboard access.

**Critical Priority:** Ensure bulletproof remote access before moving box.

---

## Repository Contents

- **HARDENING-PLAN.md** - Complete detailed hardening plan with all phases
- **SESSION-NOTES.md** - Current progress and session status
- **scripts/** (to be created) - All hardening scripts numbered 01-XX

---

## Quick Status

**Current Phase:** Planning Complete, Ready to Create Scripts
**Next Step:** Create numbered hardening scripts for execution

---

## Implementation Phases

### Phase A: Remote Access Foundation (BEFORE MOVING BOX)
- Repository configuration
- Time synchronization (NTP)
- Pre-hardening checks & backups
- SMART disk monitoring
- SSH key setup
- **Mandatory Checkpoint #1**

### Phase B: Security Hardening (BEFORE MOVING BOX)
- System updates & security tools
- Firewall configuration
- HTTPS certificate
- Proxmox backup (optional)
- SSH hardening (port 22022, keys-only)
- **Mandatory Checkpoint #2**

### 🚀 **Box Can Be Moved After Phase B**

### Phase C: Protection & Monitoring (AFTER MOVING BOX)
- Fail2ban
- Notifications (ntfy.sh)
- Additional hardening
- Monitoring & logging
- Final verification

---

## Key Security Improvements

- ✅ SSH on port 22022, key-only authentication
- ✅ Firewall with IP whitelisting (192.168.99.6)
- ✅ SMART disk health monitoring
- ✅ Automatic security updates
- ✅ Real-time alerts via ntfy.sh
- ✅ Proxmox repos configured (no subscription popup)
- ✅ Multiple remote access methods verified

---

## Target Configuration

**Trusted IP:** 192.168.99.6 (desktop - DHCP reserved in UniFi)
**SSH Port:** 22022 (non-standard)
**Web UI:** https://192.168.40.60:8006
**Notifications:** ntfy.sh (proxmox-security-alerts-ugreen)

---

## Execution Method

1. Scripts created in LXC 102 for review
2. Scripts copied to Proxmox host: `/root/proxmox-hardening/`
3. User executes each script manually (entering password when prompted)
4. Most scripts run as **root** (using sudo)
5. Phase-by-phase execution with testing checkpoints

---

## Important Notes

⚠️ **CRITICAL:** Complete BOTH mandatory checkpoints before moving box
⚠️ Always keep 2+ SSH sessions open when making changes
⚠️ Proxmox Web UI Shell is emergency backup access
⚠️ Test each change before proceeding to next phase

---

## Time Estimate

- **Phase A (before moving):** ~55 minutes
- **Phase B (before moving):** ~90-120 minutes
- **Phase C (after moving):** ~75 minutes
- **Total:** ~3.5-4 hours

---

## GitHub Repository

Repository: https://github.com/Sleszgit/proxmox-hardening
User: sleszgit
Created: 2025-12-08

---

## References

- Security assessment performed: 2025-12-08
- Current security status: WEAK (default Proxmox installation)
- Full plan details: See HARDENING-PLAN.md
