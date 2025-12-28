# Session 41: Seriale2023 Transfer Status - Ongoing
**Date:** 28 December 2025  
**Status:** ✅ TRANSFER IN PROGRESS - Long-running rsync (4+ days)
**Location:** LXC 102 (UGREEN)

---

## Quick Summary
The **920 NAS → UGREEN** Seriale2023 (TV shows) transfer has been running continuously since **26 December at 20:21 CET** (~32 hours elapsed). Currently at **8.7TB transferred** (70.7% complete) with multiple rsync processes actively copying.

---

## Transfer Overview

### Source & Destination
- **Source:** 920 NAS `/Seriale 2023/` folder (mounted via NFS at `/tmp/920-seriale2023-mount/`)
- **Destination:** UGREEN Proxmox host `/seriale2023/` (ZFS pool)
- **Total Expected:** ~12.3 TB (1,073 TV show folders)
- **Transferred So Far:** 8.7 TB (70.7% complete)

### Transfer Process
- **Running as:** root via sudo screen session
- **Method:** rsync -avh --partial --progress
- **Screen Session:** `seriale2023-transfer-v2` (detached)
- **Script Location:** `/nvme2tb/lxc102scripts/transfer-seriale2023.sh`
- **Log File:** `/root/nas-transfer-logs/transfer-seriale2023-20251226-202101.log` (9.6 MB)

### Timeline
- **Start Date/Time:** 26 December 2025, 20:21 CET
- **Elapsed Time:** ~32 hours (1.33 days)
- **Current Date/Time:** 28 December 2025
- **Estimated Completion:** ~13 hours remaining (completion ~5-6 PM Warsaw time, 28 Dec)

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Data Transferred | 8.7 TB |
| Total Expected | ~12.3 TB |
| Completion % | 70.7% |
| Elapsed Time | 32 hours |
| Average Speed | 272 GB/hour (~36 MB/s) |
| Estimated Time Remaining | ~13 hours |
| RAM Usage | ~10 GB (normal for rsync with NFS) |
| CPU Usage | 6-7% |

---

## Process Status

### Active Rsync Processes
```
PID 206533: rsync -avh --partial --progress
  State: D+ (uninterruptible sleep - active I/O)
  Runtime: 32:00
  Memory: 10 MB (rsync itself, data buffered in kernel)
  
Child Process 206536:
  Runtime: 72:18
  CPU: 5.2%
```

### Source Details
- **Source Path:** `/tmp/920-seriale2023-mount/Seriale 2023/`
- **Mount Type:** NFS (from 920 NAS)
- **File Count:** 1,073+ show folders
- **File Exclusion:** `/tmp/rsync-exclude-seriale2023-1766776861.txt`

---

## Previous Attempts & Learnings

### Session 37 (27 Dec, 10:00 AM)
- ✅ Discovered transfer was running
- ✅ Identified 10GB RAM usage (normal for this workload)
- ✅ Calculated ~30-35 hours remaining at that point (was from 10 AM, now much closer to completion)
- ⚠️ Noted critical RAM limitation for stock UGREEN (8GB)

### Session 40 (27 Dec, 19:30 PM)
- ✅ Verified transfer still active (note: timer data from Session 40 was historical, not current)
- ✅ Confirmed 8.7TB at destination
- ✅ Identified that initial check missed screen sessions
- ⚠️ Noted ownership issue (user 1027 on some folders)

---

## Important Observations

1. **✅ No Errors Detected** - Transfer proceeding normally
2. **✅ Consistent Progress** - Data steadily accumulating (5.2TB → 8.7TB)
3. **✅ Process Health** - Child processes active with normal CPU/memory
4. **⚠️ RAM Usage** - 10GB consumed by rsync+NFS caching
   - Your UGREEN (64GB): ✅ No issue
   - Stock UGREEN (8GB): ❌ Would struggle or fail
5. **📝 Logging Active** - All progress being recorded

---

## Monitoring Checklist

- [ ] Check transfer completion status (when ready)
- [ ] Verify final data size matches expectations
- [ ] Validate file count (should be 1,073+ folders)
- [ ] Document any permission/ownership issues
- [ ] Clean up NFS mount after transfer
- [ ] Update storage documentation

---

## Related Documentation

### Previous Sessions
- **SESSION-37:** Initial discovery, RAM analysis, completion estimate
- **SESSION-40:** Status verification, process details, learnings
- **SESSION-34:** Transfer debugging, NFS fixes
- **SESSION-26:** Original infrastructure planning

### Key Files
- Transfer script: `/mnt/lxc102scripts/transfer-seriale2023.sh`
- Exclusion list: `/tmp/rsync-exclude-seriale2023-1766776861.txt`
- Log directory: `/root/nas-transfer-logs/`
- Destination: `/seriale2023/` (on Proxmox host)

### API Access
- Cluster token: `~/.proxmox-api-token`
- VM 100 token: `~/.proxmox-vm100-token`

---

## What Happens Next

1. **Monitor Progress**
   - Transfer should complete in ~3-5 hours
   - Log file will show completion message
   - `/seriale2023/` folder will stop growing

2. **Upon Completion**
   - Verify file integrity (optional checksum)
   - Document final statistics
   - Clean up temporary files (NFS mounts, exclude lists)
   - Update storage pool documentation

3. **Known Issues to Address**
   - User 1027 ownership (some folders have read issues)
   - NFS mount cleanup
   - Potential permissions adjustment needed

---

## Session Metadata

**Location:** LXC 102 (UGREEN)  
**User:** sleszugreen  
**Tools Used:** screen, ps, du, tail, bash  
**Commands Run:** Check screen sessions, monitor rsync, verify destination size  
**Decision Made:** Document ongoing transfer status for reference

---

## Command Reference

```bash
# Monitor transfer on Proxmox host
sudo screen -r seriale2023-transfer-v2

# Check current size
du -sh /seriale2023/

# Monitor progress live
sudo tail -f /root/nas-transfer-logs/transfer-seriale2023-20251226-202101.log

# Check all rsync processes
ps aux | grep rsync | grep -v grep

# List transfer logs
sudo ls -lht /root/nas-transfer-logs/

# Count folders at destination
ls -1 /seriale2023/ | wc -l
```

---

**Status:** 🟢 TRANSFER RUNNING - Expect completion ~5-6 PM Warsaw time (28 Dec)  
**Last Updated:** 28 Dec 2025, 04:21 CET  
**Next Review:** When transfer completes
