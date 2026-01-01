# LXC102 Backup Strategy - Decision Log

## Consultation 1: Backup Methods & Location Analysis

**Date:** 2026-01-01
**Issue:** What backup method(s) and storage location(s) best protect LXC102?
**Consultation Status:** Claude analysis (Gemini unavailable - daily quota hit)

### Methods Analyzed
1. **Vzdump** (Proxmox native) - Full backup, easy restore
2. **Rsync over SSH** (Incremental) - Fast, file-level recovery
3. **LVM Snapshots** + tar - Consistent point-in-time
4. **Tar over SSH** - Simple, straightforward

### Storage Locations Compared
- Homelab only (isolation)
- UGREEN NAS only (convenient but risky)
- Both (redundancy) ⭐ RECOMMENDED

---

## RECOMMENDATION: HYBRID STRATEGY ⭐

### Primary Backup: Daily Vzdump → Homelab
```
What:        Proxmox native full container backup
Frequency:   Daily at 2 AM (off-peak)
Destination: Homelab NFS mount
Retention:   10 backups (7 daily + 1 weekly + 2 archive)
Size:        ~2-3GB × 10 = ~30GB total
Restore:     5-10 minutes
Purpose:     Complete disaster recovery, bare metal rebuild
```

### Secondary Backup: Hourly Rsync → UGREEN NAS
```
What:        SSH + rsync incremental sync
Frequency:   Every hour
Destination: /storage/Media/backups/lxc102-rsync/
Files:       ~/scripts/, ~/projects/, ~/.bashrc, ~/.ssh/, ~/.local/bin/
Retention:   24 hourly snapshots
Size:        ~500MB (only changed files)
Restore:     Minutes (file-level recovery)
Purpose:     Quick recovery from config corruption/accidental delete
```

### Offsite Archive: Weekly → Homelab
```
What:        Copy latest vzdump to homelab
Frequency:   Weekly (Sunday)
Retention:   4 weekly backups
Verification: Test restore quarterly
Purpose:     Long-term archive, disaster recovery
```

---

## Why This Recommendation

✅ **Redundancy** - Two independent backup locations
✅ **Speed** - Rsync for quick file-level recovery
✅ **Completeness** - Vzdump for full disaster recovery
✅ **Simplicity** - Automated, minimal manual work
✅ **Reliability** - Proven methods (Proxmox native + rsync)
✅ **Testability** - Easy to verify with restore test
✅ **Cost** - Balanced storage usage

---

## Implementation Plan

**Phase 1:** Create vzdump backup script
**Phase 2:** Set up rsync to UGREEN NAS
**Phase 3:** Test restore from vzdump
**Phase 4:** Automate with cron jobs
**Phase 5:** Document recovery procedure
**Phase 6:** Quarterly restore testing

---

## Status: ✅ APPROVED

**User Decision (2026-01-01):**
- Protecting against: Crashes during work + system corruption
- Approved: Daily rsync (not hourly)
- Reason: GitHub handles frequent commits; daily snapshot sufficient
- Strategy: GitHub (commits) + Daily Rsync (system state) + Daily Vzdump (disaster recovery)

**Final Approved Strategy:**
```
PRIMARY: Daily Vzdump → Homelab
  ├─ Time: 2 AM (off-peak)
  ├─ Retention: 10 backups
  ├─ Storage: ~30GB
  ├─ Restore: Full disaster recovery

SECONDARY: Daily Rsync → UGREEN NAS
  ├─ Time: 3 AM (after work)
  ├─ Retention: 7 daily snapshots
  ├─ Storage: ~5GB
  ├─ Files: ~/scripts/, ~/projects/, ~/.bashrc, ~/.ssh/, ~/.local/bin/
  ├─ Restore: File-level recovery

FOUNDATION: GitHub
  ├─ Frequent commits (ongoing)
  ├─ Session documentation
  ├─ Version control
```

---

**Decision Owner:** Claude (Strategic Lead) + User Approval
**Next Action:** Phase 1 Implementation - Create backup scripts
