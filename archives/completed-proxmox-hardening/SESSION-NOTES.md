# Session Notes - Proxmox Hardening Project

**Date:** 2025-12-09 (Updated - Session 3)
**Session Status:** Phase A - SSH Keys Working, Checkpoint #1 In Progress

---

## Current Status

### ✅ Completed
- [x] Security assessment of Proxmox host
- [x] User requirements gathering
- [x] Comprehensive hardening plan created
- [x] Plan approved by user
- [x] Repository structure defined
- [x] **Phase A scripts created (all 7 files)**
- [x] Scripts copied to Proxmox host (/root/proxmox-hardening/)
- [x] **Script 00: Repository setup executed** ✓
- [x] **Script 01: NTP configuration executed** ✓
- [x] **Script 02: Pre-hardening checks executed** ✓
- [x] **Script 03: SMART monitoring executed** ✓
- [x] Fixed Proxmox repository warning (removed subscription popup)
- [x] **SSH key authentication WORKING for sleszugreen** ✓
- [x] Generated new SSH key pair (no passphrase)
- [x] Key file: `C:\Users\jakub\.ssh\ugreen_key`

### 🔄 In Progress
- [ ] Add SSH key to root account
- [ ] Execute Script 05: Remote Access Test (Checkpoint #1)

### ⏳ Pending
- [ ] Complete Mandatory Checkpoint #1
- [ ] Create Phase B scripts (7 scripts)
- [ ] Execute Phase B scripts
- [ ] Complete Mandatory Checkpoint #2
- [ ] Create Phase C scripts (6 scripts)
- [ ] Move box to remote location (AFTER Checkpoint #2 passes)
- [ ] Execute Phase C scripts
- [ ] Final verification

---

## Security Assessment Summary

**Date Assessed:** 2025-12-08
**Current Security Posture:** ⚠️ WEAK

### Critical Issues Found:
- 🚨 Root SSH login enabled
- 🚨 No firewall rules configured
- 🚨 No fail2ban protection
- 🚨 SSH key authentication not enforced
- ⚠️ No automatic security updates
- ⚠️ Default SSH port 22 in use
- ⚠️ Enterprise repo not disabled (subscription popup)

### Environment Details:
- **OS:** Debian GNU/Linux 13 (Trixie)
- **Proxmox Version:** 9.1.2
- **IP Address:** 192.168.40.60
- **Current User:** sleszugreen (has sudo)
- **SSH Config:** /etc/ssh/sshd_config
- **Firewall:** pve-firewall running but no rules

---

## User Configuration

### Access Details
- **Trusted Desktop IP:** 192.168.99.6 (DHCP reserved in UniFi router)
- **Future VPN Access:** Netbird (to be configured later)
- **Physical Access:** Available NOW, will be removed after hardening

### Requirements
- **SSH Port:** Change to 22022 (non-standard but memorable)
- **SSH Authentication:** Keys-only (user needs setup guidance)
- **Notifications:** ntfy.sh (no email passwords required)
- **User Skill Level:** Computer enthusiast, not IT professional
- **Preference:** Web UIs over CLI when possible

### Critical Constraint
⚠️ **UGREEN box will be moved to remote location without monitor/keyboard**
- Must ensure bulletproof remote access BEFORE moving
- Multiple access methods required (SSH + Web UI + Web UI Shell)
- Two mandatory testing checkpoints before move

---

## Scripts to Create

### Phase A: Remote Access Foundation (7 scripts)
1. `00-repository-setup.sh` - Fix Proxmox repos
2. `01-ntp-setup.sh` - Configure time sync
3. `02-pre-hardening-checks.sh` - Backups & verification
4. `03-smart-monitoring.sh` - Disk health monitoring
5. `04-ssh-key-setup.sh` - SSH key setup with user guidance
6. `05-remote-access-test-1.sh` - Checklist script (Phase A checkpoint)
7. README-PHASE-A.md - User instructions for Phase A

### Phase B: Security Hardening (8 scripts)
8. `06-system-update.sh` - Install security tools
9. `07-firewall-setup.sh` - Configure firewall
10. `08-https-certificate.sh` - SSL cert (3 options)
11. `09-proxmox-backup.sh` - Backup setup (OPTIONAL)
12. `10-ssh-harden.sh` - SSH port 22022, keys-only
13. `11-remote-access-test-2.sh` - Checklist script (Phase B checkpoint)
14. README-PHASE-B.md - User instructions for Phase B

### Phase C: Protection & Monitoring (6 scripts)
15. `12-fail2ban-setup.sh` - Brute-force protection
16. `13-notification-setup.sh` - ntfy.sh alerts
17. `14-additional-hardening.sh` - Kernel hardening
18. `15-monitoring-setup.sh` - Logging & monitoring
19. `16-final-verification.sh` - Security audit
20. README-PHASE-C.md - User instructions for Phase C

### Supporting Files
- `99-rollback.sh` - Emergency rollback script
- `master-hardening.sh` - Run all scripts with confirmations
- Emergency recovery procedures document

**Total Scripts:** ~20+ scripts

---

## Execution Plan

### 1. Script Creation (In Progress)
- Create all scripts in LXC 102: `/home/sleszugreen/proxmox-hardening-scripts/`
- Review each script with user
- Test script syntax
- Document which user should run each script (root vs sleszugreen)

### 2. Transfer to Proxmox Host
- After user approval
- Copy entire directory to: `/root/proxmox-hardening/`
- Verify all scripts present and executable

### 3. Manual Execution by User
- Run Phase A scripts (before moving box)
- Complete Mandatory Checkpoint #1
- Run Phase B scripts (before moving box)
- Complete Mandatory Checkpoint #2
- Move box to remote location
- Run Phase C scripts (after moving box)

---

## Risk Mitigation

### Lockout Prevention
- Multiple SSH sessions open during changes
- Web UI Shell as emergency access
- Detailed testing at each step
- Configuration backups before every change
- Rollback procedures documented

### Testing Checkpoints
1. **Checkpoint #1 (After Phase A):**
   - SSH key authentication working
   - Web UI accessible
   - Web UI Shell working
   - Multiple sessions verified

2. **Checkpoint #2 (After Phase B):**
   - SSH on port 22022 working
   - Firewall not blocking desktop
   - Web UI still accessible
   - Emergency access tested

---

## Next Steps

1. Create all Phase A scripts
2. Create all Phase B scripts
3. Create all Phase C scripts
4. Create supporting scripts (rollback, master)
5. Create phase-specific README files
6. Review with user
7. Commit to GitHub
8. Copy to Proxmox host
9. Begin execution

---

## Notes & Reminders

- User will enter password manually for each sudo command
- Most scripts run as root: `sudo bash script-name.sh`
- SSH key setup can run as sleszugreen user
- Scripts should be idempotent (safe to run multiple times)
- Include confirmation prompts for destructive operations
- Log all changes to /root/proxmox-hardening/hardening.log
- Create backups before modifying any config file

---

## Repository Info

**GitHub User:** sleszgit
**Account:** Sleszgit
**Repository:** proxmox-hardening (to be created)
**Branch:** main
**License:** MIT (or user's preference)

---

## Questions Answered

1. ✅ Physical console access? YES (for now, will be removed)
2. ✅ Desktop IP confirmed? YES - 192.168.99.6 (DHCP reserved)
3. ✅ Comfortable with SSH keys? YES (with guidance needed)
4. ✅ ntfy app installed? YES
5. ✅ Execution method? Phase-by-phase manual execution

---

## Additional Items Added to Plan

Based on user request, the following critical items were added:

1. **Repository Configuration** - Fix "no subscription" popup
2. **Time Synchronization (NTP)** - Critical for certificates
3. **Emergency Remote Console Access** - Web UI Shell as backup
4. **SMART Disk Monitoring** - Prevent disk failure data loss
5. **HTTPS Certificate Options** - Self-signed, Let's Encrypt, or Internal CA
6. **Proxmox Backup Integration** - Optional PBS/NAS/USB backup setup

All items integrated into phased approach with remote access priority.

---

## Session Timeline

### Session 1: 2025-12-08
- **18:00** - Session started, entered planning mode
- **18:15** - Security assessment completed
- **18:30** - User requirements gathered
- **18:45** - Comprehensive plan created with all critical items
- **19:00** - Plan approved, ready for script creation
- **19:15** - Repository initialized, session saved

### Session 2: 2025-12-09 (Morning)
- **04:45** - Session resumed
- **04:55-05:01** - Created all Phase A scripts (00-05 + README)
- **05:06** - Copied scripts to Proxmox host
- **05:22** - Executed Script 00: Repository setup ✓
- **05:22** - Fixed repository format (.sources vs .list)
- **05:25** - Executed Script 01: NTP setup ✓
- **05:38** - Executed Script 02: Pre-hardening checks ✓
- **05:41** - Executed Script 03: SMART monitoring ✓
- **05:42** - Session paused (Scripts 04-05 pending)

### Session 3: 2025-12-09 (Evening)
- **19:00** - Session resumed, attempted Script 04 execution
- **19:10-21:30** - SSH key setup troubleshooting (~2.5 hours)
  - **Challenge:** Multiple attempts to add public key to authorized_keys
  - **Issue 1:** Key breaking into multiple lines when pasted
  - **Issue 2:** Existing Windows key (id_ed25519_ugreen) had forgotten passphrase
  - **Solution:** Generated NEW key pair on Proxmox without passphrase
- **21:15** - Created fresh SSH key pair: `/tmp/ugreen_key` (Proxmox)
- **21:27** - Copied private key to Windows: `C:\Users\jakub\.ssh\ugreen_key`
- **21:30** - ✅ **SSH key authentication WORKING for sleszugreen!**
- **21:35** - Started Script 05 (Checkpoint #1) - discovered needs root SSH key too
- **21:40** - Session paused

**Lessons Learned:**
- SSH authorized_keys MUST be single line (no line breaks)
- Windows Notepad adds wrong line endings - use direct scp copy instead
- Generating keys on Linux and copying to Windows more reliable than vice versa
- Script 05 tests root SSH access, not sleszugreen

**Next Session:**
- Add SSH public key to root's authorized_keys
- Complete Script 05: Remote Access Test (Checkpoint #1)
- Verify all 7 checkpoint tests pass before Phase B