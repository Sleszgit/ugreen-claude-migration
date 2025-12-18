#!/bin/bash
#
# Automated Git Commit Script for Proxmox Hardening Project
# This script handles all git operations without user intervention
#
# Usage: bash /home/sleszugreen/git-commit-session.sh "Commit message"
#

set -e  # Exit on error

REPO_PATH="/root/proxmox-hardening"
HOME_PATH="/home/sleszugreen"
GIT_COMMIT_MSG="${1:-Session 8: Final status review and documentation update}"

echo "======================================"
echo "Git Commit & Push Automation Script"
echo "======================================"
echo ""

# Check if repo exists
if [ ! -d "$REPO_PATH" ]; then
    echo "[ERROR] Repository not found at $REPO_PATH"
    exit 1
fi

# Navigate to repo
cd "$REPO_PATH"
echo "[INFO] Working directory: $(pwd)"
echo ""

# Check git status
echo "[STEP 1] Checking git status..."
echo "---"
git status --short || true
echo "---"
echo ""

# Create session summary in home directory (writable)
echo "[STEP 2] Creating session summary..."
cat > "$HOME_PATH/SESSION-8-FINAL-STATUS.md" << 'EOF'
# Session 8 - Final Hardening Status & Relocation Clearance
**Date:** December 13, 2025
**Status:** Phase B COMPLETE ✅ | Box Ready for Relocation 🚀

---

## Overview

This session involved comprehensive review of all completed work. Previous session notes were outdated - actual system status is far more advanced than documentation indicated.

**Key Finding:** SSH access to container (LXC 102) has been fixed, and all major hardening scripts have been successfully executed.

---

## Current System Status

### ✅ Phase B: Security Hardening - COMPLETE

All critical hardening completed and verified:

**SSH Hardening:**
- ✅ Port changed to 22022
- ✅ Password authentication DISABLED
- ✅ Root login set to prohibit-password (keys only)
- ✅ Public key authentication ENABLED
- ✅ Status: Working from both root and sleszugreen users

**Firewall:**
- ✅ Status: enabled/running
- ✅ Policy: DROP (blocks all except trusted IP)
- ✅ Trusted IP: 192.168.99.6
- ✅ Allowed ports: 22022, 8006

**Fail2ban:**
- ✅ Status: Active
- ✅ Jails: 2 (sshd, proxmox)
- ✅ SSH jail: Active
- ✅ Proxmox jail: Active

**System Updates:**
- ✅ fail2ban installed
- ✅ unattended-upgrades configured
- ✅ logwatch installed
- ✅ ufw (firewall utility) installed

**Checkpoints:**
- ✅ Checkpoint #1: PASSED
- ✅ Checkpoint #2: PASSED (2025-12-13 05:36)

---

## Relocation Readiness

### ✅ SYSTEM IS READY FOR RELOCATION

**Cleared by:**
1. ✅ Checkpoint #2 PASSED with all tests passing
2. ✅ Multiple remote access methods verified working
3. ✅ SSH hardening successfully applied
4. ✅ Firewall protecting access appropriately
5. ✅ Emergency recovery procedures documented

**Access Methods (All Working):**
```bash
# SSH Access
ssh -p 22022 -i ~/.ssh/ugreen_key root@192.168.40.60

# Web UI Access
https://192.168.40.60:8006

# Emergency Shell
Via Web UI: Node "ugreen" → Shell button
```

---

## Scripts Executed (Timeline)

| Date | Time | Script | Name | Status |
|------|------|--------|------|--------|
| 2025-12-09 | 05:22 | 00 | Repository Setup | ✅ |
| 2025-12-09 | 05:25 | 01 | NTP Configuration | ✅ |
| 2025-12-09 | 05:38 | 02 | Pre-hardening Checks | ✅ |
| 2025-12-09 | 05:41 | 03 | SMART Monitoring | ✅ |
| 2025-12-09 | xx:xx | 04 | SSH Key Setup | ✅ |
| 2025-12-09 | xx:xx | 05 | Remote Access Test #1 | ✅ |
| 2025-12-12 | 01:32 | 08 | Proxmox Backup | ✅ |
| 2025-12-12 | 02:01 | 06 | System Updates | ✅ |
| 2025-12-12 | 02:18 | 07 | Firewall Config | ✅ |
| 2025-12-13 | 05:18 | 09 | SSH Hardening | ✅ |
| 2025-12-13 | 05:36 | 10 | Checkpoint #2 | ✅ PASSED |
| 2025-12-13 | 06:00 | 11 | Fail2ban Setup | ✅ |

---

## Key Accomplishments

1. **Remote Access Secured** ✅
   - Multiple verified access methods
   - SSH keys working for all users
   - Web UI accessible and responsive

2. **SSH Hardened** ✅
   - Port: 22 → 22022
   - Authentication: Keys-only
   - Root login: Disabled password auth

3. **Firewall Configured** ✅
   - Desktop IP whitelisted (192.168.99.6)
   - Default DROP policy
   - Only necessary ports open

4. **Brute-force Protection** ✅
   - Fail2ban with 2 active jails
   - SSH protection: 3 attempts, 2-hour ban
   - Proxmox UI protection: 3 attempts, 1-hour ban

5. **System Hardening** ✅
   - Automatic security updates
   - SMART disk monitoring
   - NTP time synchronization
   - Configuration backups

---

## Next Steps (Optional)

- **Script 12:** Notification Setup (ntfy.sh integration)
- **Script 13+:** Additional Hardening enhancements

These Phase C scripts are optional and can run anytime after relocation.

---

## Conclusion

Your Proxmox system is now **fully hardened and ready for relocation without physical access**.

- ✅ Phase A: Remote Access Foundation - COMPLETE
- ✅ Phase B: Security Hardening - COMPLETE
- 🔄 Phase C: Monitoring & Protection - IN PROGRESS (optional)
- ✅ **System Status: CLEARED FOR RELOCATION**

---

**Document Generated:** December 13, 2025
**Session:** 8 (Final Status Review)
**Model:** Claude Haiku 4.5
EOF

echo "[OK] Session summary created at $HOME_PATH/SESSION-8-FINAL-STATUS.md"
echo ""

# Copy session summary to repo if writable
echo "[STEP 3] Attempting to copy session summary to repo..."
if [ -w "$REPO_PATH" ]; then
    cp "$HOME_PATH/SESSION-8-FINAL-STATUS.md" "$REPO_PATH/SESSION-8-FINAL-STATUS.md" 2>/dev/null && echo "[OK] Copied to repository" || echo "[WARN] Could not copy (permission denied)"
else
    echo "[WARN] Repository not writable (bind mount issue) - file saved to home directory"
fi
echo ""

# Add changes to git
echo "[STEP 4] Staging changes for git commit..."
git add -A 2>/dev/null || echo "[WARN] No changes to stage or git add failed"
echo ""

# Check if there are changes to commit
CHANGES=$(git status --porcelain | wc -l)
if [ "$CHANGES" -eq 0 ]; then
    echo "[INFO] No changes to commit"
    echo ""
    echo "[STEP 5] Checking git log..."
    git log --oneline -10
    echo ""
    echo "======================================"
    echo "✅ Repository is up to date"
    echo "======================================"
    exit 0
fi

# Commit changes
echo "[STEP 5] Creating git commit..."
git commit -m "$(cat <<'COMMIT_MSG'
Session 8: Final status review - Phase B complete, box ready for relocation

Summary:
- Reviewed all completed hardening work from previous sessions
- Verified SSH access to container (LXC 102) is working
- Confirmed all Phase B scripts executed successfully
- Checkpoint #2 PASSED - system verified and hardened
- Created comprehensive final status documentation

Current Status:
✅ Phase A: Remote Access Foundation - COMPLETE
✅ Phase B: Security Hardening - COMPLETE
🔄 Phase C: Monitoring & Protection - IN PROGRESS (optional)
✅ Box cleared for relocation without monitor/keyboard access

Security Status:
✅ SSH on port 22022 with keys-only authentication
✅ Firewall configured with trusted IP whitelist (192.168.99.6)
✅ Fail2ban active with 2 jails (SSH + Proxmox)
✅ Automatic security updates configured
✅ Multiple redundant access methods verified working
✅ Emergency recovery procedures documented

Access Methods:
- SSH: ssh -p 22022 -i ~/.ssh/ugreen_key root@192.168.40.60
- Web UI: https://192.168.40.60:8006
- Emergency Shell: Via Web UI Node button

Files Created:
- SESSION-8-FINAL-STATUS.md (session summary)
- PROXMOX-HARDENING-CURRENT-STATUS.md (detailed status report)

Model: Claude Haiku 4.5
Generated with Claude Code
COMMIT_MSG
)"

echo "[OK] Commit created successfully"
echo ""

# Get commit hash
COMMIT_HASH=$(git rev-parse --short HEAD)
echo "[INFO] Commit hash: $COMMIT_HASH"
echo ""

# Push to GitHub
echo "[STEP 6] Pushing to GitHub..."
if git push origin main 2>&1; then
    echo "[OK] Push successful"
else
    echo "[WARN] Push failed (may not have git credentials configured)"
fi
echo ""

# Show final log
echo "[STEP 7] Verifying commit in log..."
git log --oneline -5
echo ""

echo "======================================"
echo "✅ Session saved and committed"
echo "======================================"
echo ""
echo "Documentation files:"
echo "  - /home/sleszugreen/SESSION-8-FINAL-STATUS.md"
echo "  - /home/sleszugreen/PROXMOX-HARDENING-CURRENT-STATUS.md"
echo ""
echo "Repository: https://github.com/Sleszgit/proxmox-hardening.git"
echo ""
