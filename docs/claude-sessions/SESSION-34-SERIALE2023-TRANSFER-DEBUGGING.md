# SESSION 34: Seriale 2023 Transfer Script Debugging & Fixes - 26 Dec 2025

**Status:** ✅ SCRIPT READY - Transfer pending restart due to NFS hang

**Duration:** ~3 hours (planning, debugging, script updates)

---

## Problem Discovered

### Initial Issue: Wrong Folder Count
- Script reported 1083 folders "already copied" in `/seriale2023/`
- User correctly identified: only 363 TV shows on UGREEN (in `/storage/Media/series920part/`)
- **Root cause:** `/seriale2023/` contained 1083 **empty skeleton folders** from a previous failed transfer attempt + 69GB of partial data

### Solution
1. **Clean analysis:** User ran diagnostic commands to identify actual storage locations
2. **Found two separate locations:**
   - `/storage/Media/series920part/` = 363 valid TV shows (earlier transfer)
   - `/seriale2023/` = 1083 empty skeletons + 69GB partial data (broken transfer)

---

## Script Improvements Made

### 1. Smart Exclusion Logic
**Before:** Script couldn't exclude already-transferred shows  
**After:** Script now:
- Reads 363 show names from `/storage/Media/series920part/`
- Adds them to rsync exclude list automatically
- Only transfers shows NOT in that directory

```bash
# Step 2: Check for already-transferred shows
if [ -d "$EXISTING_SHOWS" ]; then
    EXISTING_COUNT=$(ls -1 "$EXISTING_SHOWS" 2>/dev/null | wc -l)
    # ... add to exclude list
fi
```

### 2. Dynamic Size Calculation
**Before:** Hardcoded "~1.2TB" (WRONG - was off by 10x!)  
**After:** Script calculates actual expected size:
```bash
EXPECTED_SIZE=$(du -sb "$TEMP_MOUNT/$NAS_TV_SHOWS_SUBDIR/" 2>/dev/null | awk \
  -v shows="$SHOWS_TO_TRANSFER" -v total="$SOURCE_COUNT" \
  '{printf "%.1f", ($1 / total * shows / 1099511627776)}')
```

**Result:** Correctly shows ~12.3TB (not 1.2TB)

### 3. Corrected Variable Order
- Fixed: `SHOWS_TO_TRANSFER` now calculated BEFORE size calculation uses it
- Prevents size calculation from having undefined variables

---

## Transfer Plan (Correct)

**Source:** 920 NAS `/volume1/Seriale 2023/Seriale 2023/`
- Total: 1436 TV show folders
- Total size: ~17TB

**Target:** UGREEN `/seriale2023/` ZFS pool
- Currently: Empty (deleted 1083 broken skeletons)
- Will receive: 1073 new shows

**Exclude:** `/storage/Media/series920part/`
- 363 already-transferred shows (skip these)
- System folders: @eaDir, #recycle, do skasowania

**Expected transfer:** 1073 folders × ~12.3TB = accurate proportion

---

## NFS Hang Issue Encountered

### Symptoms
- rsync hung at "sending incremental file list"
- No progress for 25+ minutes
- No files being accessed (lsof showed nothing)
- Process still in D+ state (disk wait)

### Root Cause
- Old mount points from previous script attempts:
  - `/mnt/920-seriale-xfer` (from earlier run)
  - `/mnt/920-nfs-seriale` (from earlier run)
  - `/mnt/920-test` (from manual testing)
- These stale mounts may have caused NFS issues
- Script expected mount at `/tmp/920-seriale2023-mount/` but used different paths

### Solution Applied
1. Killed hung rsync processes: `sudo killall rsync`
2. Lazy-unmounted stale NFS mounts: `sudo umount -l /mnt/920-*`
3. Verified NFS unmounted: `mount | grep 920`
4. Cleaned up all old screen sessions: `killall screen`
5. Ready for clean restart

---

## Key Files Updated

### `/home/sleszugreen/scripts/nas/transfer-seriale2023.sh`
- ✅ Added check for `/storage/Media/series920part/`
- ✅ Dynamic rsync exclude list generation (363 shows)
- ✅ Dynamic size calculation (~12.3TB)
- ✅ Fixed variable calculation order
- ✅ Copied to bind mount: `/mnt/lxc102scripts/transfer-seriale2023.sh`

---

## Troubleshooting Insights

### What We Learned
1. **NFS mount stability:** Long NFS operations need proper timeout config
2. **Script path consistency:** Script was creating mounts at wrong locations
3. **Stale mount cleanup:** Old failed attempts leave mounts that interfere with new ones
4. **rsync file list building:** Can take 10-30 minutes for 1073 folders with thousands of files

### For Next Session
- Monitor rsync more closely during file list phase
- Consider adding rsync progress monitoring to the script
- Clean up old mount points automatically at script start
- Add timeout protection to NFS mount options

---

## Ready for Next Run

**To restart transfer:**
```bash
screen -S seriale2023-transfer
sudo bash /nvme2tb/lxc102scripts/transfer-seriale2023.sh
```

**Expected:**
- Clean NFS mount (no stale mounts interfering)
- 1073 folders to transfer
- ~12.3TB of data
- Progress should appear after file list phase completes

**Monitoring:**
```bash
# Check if still running
ps aux | grep rsync

# View progress
screen -r seriale2023-transfer
```

---

## Session Summary

| Task | Status | Notes |
|------|--------|-------|
| Identify broken /seriale2023 folders | ✅ Completed | Found 1083 empty skeletons + 69GB partial |
| Locate actual transfers on UGREEN | ✅ Completed | 363 in /storage/Media/series920part/ |
| Update script for smart exclusion | ✅ Completed | Auto-reads 363 folders to exclude |
| Add dynamic size calculation | ✅ Completed | Shows ~12.3TB (accurate) |
| Fix variable calculation order | ✅ Completed | SHOWS_TO_TRANSFER now calculated first |
| Debug NFS hang issue | ✅ Completed | Cleaned up stale mount points |
| Clean transfer environment | ✅ Completed | All old mounts unmounted, screen sessions killed |

**Next Action:** Restart script with clean environment and monitor progress

---

## FINAL UPDATE: Transfer Successfully Started ✅

### Issue Resolution
- **Problem:** rsync hung at "sending incremental file list" with `--checksum` flag
- **Root cause:** `--checksum` forces rsync to read and verify every file before starting transfer (very slow with 1073 folders)
- **Solution:** Removed `--checksum` flag from rsync command
- **Result:** Transfer now progressing smoothly at 90-112 MB/s

### Current Transfer Status (as of 26 Dec 2025, 20:40 CET)
- **Started:** Fri Dec 26, 20:15 CET
- **Current data size:** 237GB
- **Data transferred:** ~168GB (since fresh start)
- **Progress:** ~1.4% of 12.3TB
- **Speed:** Consistent 90-112 MB/s
- **Status:** ✅ RUNNING - Transfer proceeding smoothly

### Time Estimate
- **Elapsed:** ~30 minutes
- **Remaining:** ~35-40 hours
- **Estimated completion:** Sunday Dec 28, 7-11 AM CET

### Monitoring Commands
```bash
# Check progress without attaching to screen
du -sh /seriale2023/

# Reconnect to see detailed progress
screen -r seriale2023-transfer
```

### Key Learnings
1. **rsync `--checksum` flag:** Useful for verification but causes bottleneck during initial file list phase with large transfers
2. **Screen detach:** Ctrl+A then D properly detaches without killing process
3. **Safe terminal close:** Closing SSH doesn't affect background screen sessions
4. **NFS mount timeout:** Default timeo=30 works fine for this transfer rate

### Files Updated
- `/home/sleszugreen/scripts/nas/transfer-seriale2023.sh` - Removed `--checksum` flag
- `/mnt/lxc102scripts/transfer-seriale2023.sh` - Bind mount copy updated

---

## User Notes

- User not IT professional - explain technical concepts clearly
- User prefers accuracy over speed - thorough debugging preferred
- User catches calculation errors quickly - validate math carefully
- NFS mount issues are concerning - need better error handling in script
- User values confirmation and verification before making changes

---

**Last Updated:** 26 Dec 2025, 20:40 CET
**Status:** ✅ TRANSFER IN PROGRESS - Monitoring recommended
**Next Check:** December 27-28 to verify completion

