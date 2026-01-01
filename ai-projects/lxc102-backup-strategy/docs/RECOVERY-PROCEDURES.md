# LXC102 Recovery Procedures

**Created:** 2026-01-01
**Purpose:** Step-by-step procedures for different disaster recovery scenarios
**Owner:** Claude (Strategic Lead)

---

## Overview

This document describes recovery procedures for LXC102 when data loss or container failure occurs.

**Two recovery strategies:**
1. **Quick Recovery** - Restore individual files from daily rsync snapshots (5-15 minutes)
2. **Full Recovery** - Restore entire container from vzdum backup (10-30 minutes)

---

## Scenario 1: File Corruption or Accidental Deletion (Quick Recovery)

**Symptoms:**
- Specific file is missing or corrupted
- Container is still running
- Most data is intact

**Time to recovery:** 5-15 minutes

### Procedure: Restore Single File from Rsync Snapshot

```bash
# Step 1: List available snapshots
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/restore-lxc102.sh list-rsync

# Output shows available dates:
# daily-2026-01-01
# daily-2025-12-31
# daily-2025-12-30
# ...

# Step 2: Identify which snapshot has the good file
# Choose the most recent snapshot BEFORE the file was corrupted

# Step 3: Restore the file
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/restore-lxc102.sh \
  restore-rsync 2026-01-01 \
  ~/.bashrc \
  ~/.bashrc.restored

# Step 4: Verify the restored file
diff ~/.bashrc.restored ~/.bashrc.backup    # Compare with previous backup
cat ~/.bashrc.restored                      # Review file contents

# Step 5: Use the restored file
cp ~/.bashrc.restored ~/.bashrc             # Overwrite corrupted file
# OR restore to alternate location and manually merge if partial recovery
```

**Examples:**

```bash
# Restore a script
./restore-lxc102.sh restore-rsync 2026-01-01 ~/scripts/auto-update.sh

# Restore SSH configuration
./restore-lxc102.sh restore-rsync 2026-01-01 ~/.ssh/config

# Restore entire .bashrc directory
./restore-lxc102.sh restore-rsync 2026-01-01 ~/.local/bin

# Restore to alternate location (to compare before overwriting)
./restore-lxc102.sh restore-rsync 2026-01-01 ~/.bashrc ~/.bashrc.from-backup
```

**Important Notes:**
- Original file is automatically backed up with `.backup.YYYYMMDD-HHMMSS` extension
- Rsync snapshots are retained for 7 days (one per day)
- Metadata file (`.backup-metadata`) shows what was backed up and when

---

## Scenario 2: System Configuration Corruption (System Recovery)

**Symptoms:**
- SSH is broken, preventing login
- Package manager is corrupted
- System packages are missing/broken

**Time to recovery:** 30-60 minutes (container stays running, manual fixes)

### Procedure: Selective Configuration Restore

```bash
# Step 1: Access container (may require Proxmox console if SSH is broken)
# From Proxmox host:
sudo pct enter 102

# Step 2: List available rsync snapshots from last known-good state
ls -1 /storage/Media/backups/lxc102-rsync/daily-* | sort -r | head -5

# Step 3: Check what the problem is
cat ~/.ssh/config                        # Verify SSH config
apt list --installed | head -20          # Check packages
systemctl status ssh                     # Check SSH service

# Step 4: Identify the last snapshot before the corruption
# (use your knowledge of when the issue started)

# Step 5: Selectively restore configuration files
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/restore-lxc102.sh \
  restore-rsync 2025-12-30 \
  ~/.ssh/authorized_keys

# Step 6: Restore and manually rebuild
# Option A: Restore the entire directory
./restore-lxc102.sh restore-rsync 2025-12-30 ~/.local/bin

# Option B: Selective file restore
./restore-lxc102.sh restore-rsync 2025-12-30 ~/scripts/auto-update.sh

# Step 7: After manual investigation, commit working state
git add .
git commit -m "Recovery: Restored [files] from 2025-12-30 snapshot after [issue]"
```

**Critical Files to Restore First:**
1. `~/.ssh/` - Restore SSH access
2. `~/.bashrc` - Restore shell configuration
3. `~/scripts/` - Restore custom utilities
4. `~/.local/bin/` - Restore installed tools

**Steps to Recovery:**
1. Restore SSH configuration → Regain remote access
2. Restore shell config → Fix CLI environment
3. Restore critical scripts → Restore automation
4. Verify services → Ensure everything works
5. Commit to Git → Document the recovery

---

## Scenario 3: Complete Container Failure (Full Recovery)

**Symptoms:**
- Container won't boot
- Disk corruption detected
- Hardware failure
- Need to start from scratch

**Time to recovery:** 20-40 minutes (full container restore)

### Prerequisites
- Access to Proxmox host (192.168.40.60) with sudo
- Recent vzdump backup on Homelab (192.168.40.40)
- Container ID 102 is no longer usable (will be deleted and recreated)

### Procedure: Full Container Restore from Vzdump

```bash
# ============================================================================
# STEP 1: Access Proxmox Host
# ============================================================================
# From LXC102 container:
ssh sshadmin@192.168.40.40
# OR use Proxmox web UI if SSH is unavailable

# ============================================================================
# STEP 2: Stop the Broken Container (if still running)
# ============================================================================
sudo pct stop 102
# Wait for container to shut down
sleep 5

# ============================================================================
# STEP 3: Backup Current Container Configuration (Safety Precaution)
# ============================================================================
sudo pct config 102 > /tmp/lxc102-config-before-restore.txt

# ============================================================================
# STEP 4: Verify Available Backups
# ============================================================================
ssh backup-user@192.168.40.40 "ls -lh /mnt/homelab-backups/lxc102-vzdump/"

# Output should show available backups:
# lxc102-2026-01-01-020000.tar.zst (size: 2.3G)
# lxc102-2025-12-31-020000.tar.zst (size: 2.3G)
# lxc102-2025-12-30-020000.tar.zst (size: 2.2G)

# ============================================================================
# STEP 5: Choose Backup to Restore
# ============================================================================
# Select the MOST RECENT backup before the failure occurred
# If you're unsure, choose the most recent one:
BACKUP_FILE="lxc102-2026-01-01-020000.tar.zst"
BACKUP_HOST="backup-user@192.168.40.40"
BACKUP_PATH="/mnt/homelab-backups/lxc102-vzdump"

# ============================================================================
# STEP 6: Download Backup to Proxmox Host
# ============================================================================
echo "Downloading backup from Homelab..."
rsync -avz --progress \
  "${BACKUP_HOST}:${BACKUP_PATH}/${BACKUP_FILE}" \
  /var/lib/vz/dump/

# Wait for download to complete (may take 10-20 minutes depending on size)

# Verify download completed successfully
ls -lh "/var/lib/vz/dump/${BACKUP_FILE}"

# ============================================================================
# STEP 7: Delete the Broken Container (Safety: Backup Config First)
# ============================================================================
echo "WARNING: About to delete container 102"
read -p "Type 'DELETE' to confirm: " confirm
if [[ "${confirm}" == "DELETE" ]]; then
  sudo pct destroy 102
  echo "Container 102 deleted"
  sleep 5
else
  echo "Cancelled. Container not deleted."
  exit 1
fi

# ============================================================================
# STEP 8: Restore Container from Backup
# ============================================================================
echo "Restoring LXC102 from backup: ${BACKUP_FILE}"
sudo pct restore 102 "/var/lib/vz/dump/${BACKUP_FILE}" \
  --storage local-lvm

# Monitor the restore process
# Output shows:
# Extracting archive...
# Restoring configuration...
# Done

# ============================================================================
# STEP 9: Verify Container Configuration
# ============================================================================
sudo pct config 102

# Verify important settings:
# - hostname: ugreen-ai-terminal
# - arch: amd64
# - cores: 4
# - memory: 4096
# - root disk size: >= 20GB

# ============================================================================
# STEP 10: Start the Restored Container
# ============================================================================
sudo pct start 102
sleep 10

# Verify it's running
sudo pct status 102
# Output: "running"

# ============================================================================
# STEP 11: Connect to Restored Container
# ============================================================================
sudo pct shell 102
# OR via SSH from another system:
ssh sleszugreen@192.168.40.60

# ============================================================================
# STEP 12: Verify Container Functionality
# ============================================================================
# Inside the container:

# Check basic system
hostname                        # Should show: ugreen-ai-terminal
whoami                          # Should show: sleszugreen
pwd                             # Should show: /home/sleszugreen

# Verify critical data is restored
ls -la ~/.ssh/                  # SSH keys present?
ls -la ~/scripts/               # Scripts present?
ls -la ~/projects/              # Projects present?
cat ~/.bashrc | head -5         # Configuration OK?

# Check services
systemctl status ssh            # SSH running?
systemctl status --user         # User services OK?

# Verify networking
ping -c 1 8.8.8.8              # Network connectivity?
curl -I https://github.com      # External access?

# ============================================================================
# STEP 13: Verify Latest Data
# ============================================================================
# Check if recent work is present
git log --oneline | head -10    # Recent commits?
ls -lt ~/projects/*/| head -10  # Recent project files?

# ============================================================================
# STEP 14: Full Recovery Validation
# ============================================================================
# Run comprehensive validation
/home/sleszugreen/scripts/auto-update.sh --verify
# (or your equivalent verification script)

# ============================================================================
# STEP 15: Document the Recovery
# ============================================================================
# Create a recovery session note
cat > ~/docs/claude-sessions/RECOVERY-$(date +%Y%m%d-%H%M%S).md <<'EOF'
# Container Recovery Session

**Date:** 2026-01-01
**Incident:** Container 102 failure
**Backup Used:** lxc102-2026-01-01-020000.tar.zst
**Time to Recovery:** [Duration]

## What Happened
[Description of the incident]

## Recovery Steps Taken
1. Accessed Proxmox host
2. Stopped failed container
3. Downloaded backup from Homelab
4. Deleted failed container
5. Restored from backup
6. Verified all systems operational

## Verification Completed
- [x] Container boots
- [x] SSH access works
- [x] All home directories present
- [x] Scripts and projects restored
- [x] Services running
- [x] Network connectivity

## Lessons Learned
[Any changes to procedures or configurations]

## Next Steps
- Commit recovery procedures to git
- Document any missing data
- Update backup test schedule
EOF

# ============================================================================
# STEP 16: Commit to Git and GitHub
# ============================================================================
cd ~
git add docs/claude-sessions/RECOVERY-*.md
git commit -m "Recovery: Restored LXC102 from backup - Incident documentation"
git push
```

**Time Breakdown:**
- Download backup: 10-20 minutes (depends on size and network)
- Delete container: 1 minute
- Restore from backup: 5-10 minutes
- Verification: 5-10 minutes
- Total: 20-50 minutes

---

## Scenario 4: Partial Data Loss (Advanced Recovery)

**Symptoms:**
- Specific project directory is missing or corrupted
- Git history is lost but source files might be in backup
- Need to recover from multiple snapshots

### Procedure: Recover Deleted Project Directory

```bash
# Step 1: List all available rsync snapshots
./restore-lxc102.sh list-rsync

# Step 2: Check each snapshot for the deleted directory
for snapshot in daily-*; do
  echo "Checking $snapshot..."
  ls "/storage/Media/backups/lxc102-rsync/${snapshot}/projects/my-project/" 2>/dev/null && \
    echo "Found in $snapshot"
done

# Step 3: Find the snapshot with the most complete version
ls -la "/storage/Media/backups/lxc102-rsync/daily-2026-01-01/projects/my-project/"

# Step 4: Restore the project
./restore-lxc102.sh restore-rsync 2026-01-01 ~/projects/my-project

# Step 5: Verify the recovered project
cd ~/projects/my-project
git log --oneline | head -10       # Check git history
ls -la                             # Check files

# Step 6: If partial recovery, merge with other snapshots
# (manually review and combine the best version)
```

---

## Quarterly Restore Testing (Mandatory)

**Frequency:** Every quarter (Jan 1, Apr 1, Jul 1, Oct 1)
**Purpose:** Verify backups actually work before a real disaster

### Test Procedure

```bash
# STEP 1: Choose a test date
TEST_DATE="2026-01-01"

# STEP 2: From Proxmox host, download latest vzdump
ssh backup-user@192.168.40.40 \
  "ls -t /mnt/homelab-backups/lxc102-vzdump/lxc102-*.tar.* | head -1"

# STEP 3: Create test container (don't overwrite production)
# Download backup and restore to container ID 200 (test)
sudo pct restore 200 "/var/lib/vz/dump/[BACKUP_FILE]" \
  --storage local-lvm

# STEP 4: Boot test container
sudo pct start 200
sleep 15

# STEP 5: Verify boot and login
sudo pct shell 200 "hostname"
sudo pct shell 200 "ls -la /home/sleszugreen/"

# STEP 6: Document test results
cat > ~/docs/RECOVERY-TEST-RESULTS.md <<EOF
# Recovery Test - 2026-01-01

**Test Status:** ✅ PASSED

**Backup Used:** lxc102-2026-01-01-020000.tar.zst
**Test Container:** 200
**Boot Time:** [Time in seconds]

**Verification:**
- [x] Container boots successfully
- [x] SSH login works
- [x] Home directories present
- [x] Critical files verified
- [x] Git history intact

**Issues Found:** None

**Recommendation:** Ready for production. Next test: 2026-04-01
EOF

# STEP 7: Cleanup test container
sudo pct destroy 200

# STEP 8: Commit test results
git add docs/RECOVERY-TEST-RESULTS.md
git commit -m "Quarterly recovery test: 2026-01-01 - PASSED"
git push
```

---

## Emergency Contacts & Resources

**Proxmox Documentation:**
- Container restore: https://pve.proxmox.com/wiki/LXC#Restore_a_Backup

**Homelab Infrastructure:**
- Host: 192.168.40.40
- Backup user: backup-user
- Backup location: /mnt/homelab-backups/lxc102-vzdump

**UGREEN NAS:**
- Mount: /storage/Media
- Backup location: /storage/Media/backups/lxc102-rsync

---

## Checklist: Before You Restore

- [ ] Backup is verified to exist
- [ ] You know the date of the last known-good state
- [ ] You have access to Proxmox host (or console)
- [ ] You have sufficient disk space for download + restore
- [ ] You've documented the failure (incident notes)
- [ ] For full restore: Container is stopped
- [ ] For full restore: Configuration has been backed up

---

## Checklist: After You Restore

- [ ] Container is running
- [ ] SSH login works
- [ ] Home directory verified
- [ ] Critical files present
- [ ] Services are running
- [ ] Network connectivity OK
- [ ] Incident documentation complete
- [ ] Recovery procedures updated
- [ ] Changes committed to git

---

**Owner:** Claude Code
**Last Updated:** 2026-01-01
**Review Frequency:** Quarterly (tested every 3 months)
