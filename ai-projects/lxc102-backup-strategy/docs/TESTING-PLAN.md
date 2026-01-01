# LXC102 Backup Scripts - Testing Plan

**Created:** 2026-01-01
**Status:** Prerequisites Phase
**Owner:** Claude (Strategic Lead)

---

## Overview

Three backup scripts have been created and are ready for testing:
1. **backup-lxc102-vzdump.sh** - Daily full container backup → Homelab
2. **backup-lxc102-rsync.sh** - Daily incremental files → UGREEN NAS
3. **restore-lxc102.sh** - Disaster recovery / file restoration

All scripts have passed syntax validation with `bash -n`.

---

## Prerequisites Checklist

### System Prerequisites (Common)

- [x] Bash shell available
- [x] rsync installed (for transfers)
- [x] ssh key-based authentication configured
- [x] Sudo access on Proxmox host (for vzdump script)
- [x] Container 102 exists and is accessible

### For Vzdump Backup Script

- [ ] SSH access from UGREEN to Homelab (test SSH key auth)
- [ ] Backup user `backup-user` exists on Homelab with passwordless SSH key
- [ ] Proxmox API access on Homelab (for remote backup directory)
- [ ] NFS mount on Homelab at `/mnt/homelab-backups/lxc102-vzdump/`
- [ ] Write permissions in destination directory
- [ ] Proxmox host firewall allows rsync transfer (port 873 or SSH tunneling)

**Status:** ⏳ BLOCKED - Homelab backup destination not configured

### For Rsync Backup Script

- [x] Script can access LXC102 home directory
- [x] rsync is installed in container
- [ ] UGREEN NAS mount at `/storage/Media` available in container
- [ ] Write permissions in `/storage/Media/backups/lxc102-rsync/`
- [ ] Daily snapshot directory can be created

**Status:** ⏳ BLOCKED - NAS mount not configured in container

### For Restore Script

- [ ] SSH access to Homelab for downloading vzdump backups
- [ ] Temporary storage space for backup files during restore
- [ ] NAS mount accessible for rsync snapshot restoration
- [ ] Proper file permissions for restored files

**Status:** ⏳ BLOCKED - Depends on NAS and SSH setup

---

## Testing Phases

### Phase 1: Syntax & Structure Validation ✅ COMPLETE

**Date:** 2026-01-01
**Result:** ALL PASSED

```
backup-lxc102-vzdump.sh ✓ Syntax OK
backup-lxc102-rsync.sh ✓ Syntax OK
restore-lxc102.sh ✓ Syntax OK
```

**Details:**
- All scripts validated with `bash -n`
- No syntax errors detected
- Scripts are executable with proper permissions

---

### Phase 2: Prerequisites Configuration ⏳ IN PROGRESS

#### 2a: Configure Homelab Backup Destination

**Steps:**
1. SSH to Homelab (192.168.40.40)
2. Create NFS export for backup directory:
   ```bash
   mkdir -p /mnt/homelab-backups/lxc102-vzdump
   chown backup-user:backup-user /mnt/homelab-backups/lxc102-vzdump
   chmod 755 /mnt/homelab-backups/lxc102-vzdump
   ```
3. Add NFS export to `/etc/exports`:
   ```
   /mnt/homelab-backups/lxc102-vzdump 192.168.40.60(rw,sync,no_subtree_check)
   ```
4. Export NFS: `sudo exportfs -ra`
5. Test SSH connectivity from UGREEN to Homelab
6. Test SSH rsync access (dry run)

**Prerequisites Met:** ⏳ Pending

#### 2b: Configure UGREEN NAS Mount in Container

**Steps:**
1. Create mount point in container:
   ```bash
   mkdir -p /storage/Media/backups/lxc102-rsync
   ```
2. (If using NFS mount from Proxmox host) Add to pct config:
   ```
   mp2: /storage/Media,mp=/storage/Media
   ```
3. Verify mount is accessible:
   ```bash
   touch /storage/Media/backups/lxc102-rsync/.test
   ```
4. Test write permissions for sleszugreen user

**Prerequisites Met:** ⏳ Pending

#### 2c: Verify SSH Key Authentication

**Steps:**
1. Test SSH to Homelab from container:
   ```bash
   ssh -v backup-user@192.168.40.40 "echo 'SSH works'"
   ```
2. Ensure SSH key is loaded (check ~/.ssh/)
3. Test SSH from Proxmox host as root:
   ```bash
   sudo ssh backup-user@192.168.40.40 "echo 'SSH works'"
   ```

**Prerequisites Met:** ⏳ Pending

---

### Phase 3: Dry-Run Testing (No Actual Backup Creation)

**Objective:** Validate script logic without creating large backup files

#### Test 3a: Vzdump Script - Prerequisites Check
```bash
# On Proxmox host:
sudo /mnt/lxc102scripts/backup-lxc102-vzdump.sh 2>&1 | grep -E "(ERROR|Prerequisites|Connectivity)"
```

**Expected:** All prerequisite checks pass (or identified what's missing)

#### Test 3b: Rsync Script - Dry Run
```bash
# In container:
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh 2>&1 | head -50
```

**Expected:** Script identifies missing NAS mount or creates snapshot

#### Test 3c: Restore Script - List Available Backups
```bash
# List vzdump backups:
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/restore-lxc102.sh list-vzdump

# List rsync snapshots:
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/restore-lxc102.sh list-rsync
```

**Expected:** Lists available backups (if any exist)

**Prerequisites Met:** ⏳ After Phase 2

---

### Phase 4: Integration Testing (With Actual Backups)

#### Test 4a: Create Test Vzdump Backup
```bash
# On Proxmox host (after Phase 2 complete):
sudo /mnt/lxc102scripts/backup-lxc102-vzdump.sh
```

**Expected:**
- Vzdump creates backup
- Backup transferred to Homelab
- Log file shows successful completion
- Old backups cleaned up per retention policy

**Duration:** ~10-30 minutes (depends on container size)

#### Test 4b: Create Test Rsync Snapshot
```bash
# In container (after Phase 2 complete):
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh
```

**Expected:**
- Daily snapshot created with date stamp
- Files synced to NAS
- Metadata file created with summary
- Old snapshots cleaned up per retention policy

**Duration:** ~5-10 minutes

#### Test 4c: Verify Backup Integrity
```bash
# Verify vzdump exists on Homelab:
ssh backup-user@192.168.40.40 "ls -lh /mnt/homelab-backups/lxc102-vzdump/"

# Verify rsync snapshot exists on NAS:
ls -lh /storage/Media/backups/lxc102-rsync/daily-*
```

**Expected:** Both backup locations contain recent files

---

### Phase 5: Restore Testing (Validation Before Production)

#### Test 5a: Partial File Restore (Low Risk)
```bash
# Restore a test file from rsync snapshot:
./restore-lxc102.sh restore-rsync 2026-01-01 ~/.bashrc ~/.bashrc.restored

# Verify restored file:
diff ~/.bashrc ~/.bashrc.restored
```

**Expected:** File restored successfully and matches original

#### Test 5b: Full Container Restore (High Risk - Dry Run)
```bash
# List available backup:
./restore-lxc102.sh list-vzdump

# Review backup:
./restore-lxc102.sh restore-vzdump lxc102-2026-01-01-020000.tar.zst
```

**Expected:** Script downloads backup and shows restore instructions

#### Test 5c: Quarterly Restore Validation (Scheduled)
**Frequency:** Once per quarter (Jan 1, Apr 1, Jul 1, Oct 1)
**Procedure:**
- Create test container from latest vzdump backup
- Verify container boots successfully
- Check all critical files/configs are present
- Document results
- Delete test container

---

## Current Status

### ✅ Complete
- Syntax validation (all scripts pass `bash -n`)
- Script copies to shared mount (/mnt/lxc102scripts)
- Testing plan created
- Restore script includes help/list functionality

### ⏳ Blocked (Waiting for Prerequisites)
- Homelab backup destination configuration
- NAS mount configuration in container
- SSH key authentication setup
- Dry-run testing (depends on above)
- Integration testing (depends on above)
- Restore testing (depends on above)

### 📋 Next Steps
1. **Configure Homelab backup destination** (Session 2)
2. **Configure NAS mount in container** (Session 2)
3. **Run Phase 3 dry-run tests** (Session 2)
4. **Run Phase 4 integration tests** (Session 3)
5. **Set up cron automation** (Session 4)
6. **Document recovery procedures** (Session 4)

---

## Notes

- **Log files:**
  - Vzdump: `/var/log/lxc102-vzdump-backup.log`
  - Rsync: `~/logs/lxc102-rsync-backup.log`

- **Backup locations:**
  - Vzdump backups: Homelab at `/mnt/homelab-backups/lxc102-vzdump/`
  - Rsync snapshots: UGREEN NAS at `/storage/Media/backups/lxc102-rsync/`

- **Critical files to validate during restore:**
  - ~/.bashrc, ~/.bash_profile, ~/.bash_aliases
  - ~/.ssh/ (permissions critical)
  - ~/scripts/ (all custom scripts)
  - ~/.local/bin/ (installed tools)

---

**Owner:** Claude Code
**Last Updated:** 2026-01-01
**Review Frequency:** After each testing phase completion
