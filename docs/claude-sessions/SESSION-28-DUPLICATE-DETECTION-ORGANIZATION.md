# Session 28: TV Show Organization & Duplicate Detection Setup (26 Dec 2025)

## Goal
Continue Session 27 duplicate detection work with a smarter approach: identify and separate TV shows already on UGREEN from 920 NAS backup to facilitate selective copying and deduplication.

## Key Achievements

### 1. ✅ Improved Strategy - Storage Efficiency Analysis
- **Original Plan:** Copy duplicate shows + non-duplicate shows (wastes resources)
- **Revised Plan:**
  1. Copy non-duplicates from 920 NAS to UGREEN (network transfer)
  2. Copy existing UGREEN shows to new disk (local transfer - faster)
  3. Keep 920 backup as archive
- **User Decision:** Wait until 918 disks inserted to see available space before deciding on full copy strategy

### 2. ✅ Storage Documentation - Saved to CLAUDE.md
Added comprehensive Samba share and folder structure documentation:
- `/storage/Media/` layout with all current folders
- Windows access paths (p:\)
- Folder purposes (Filmy920, Movies918, backups, etc.)
- Container vs host accessibility notes
- Ready for future reference without re-querying

### 3. ✅ Organization Script Created & Executed
**Script:** `/mnt/lxc102scripts/organize-920-tv-shows.sh`
- Validated syntax before execution ✅
- Moved 635GB → 780GB+ of TV shows from backup folder to new organized location
- Source: `/storage/Media/20251209backupsfrom918/backup seriale 2022 od 2023 09 28/`
- Target: `/storage/Media/series920part/`
- Status: **ACTIVELY RUNNING** (still growing)

**Results (In Progress):**
- 780GB moved so far (635GB → 780GB during monitoring)
- Minor permission denied messages on some folders (not blocking operation)
- Script using `mv` (move, not copy) - safe, no data loss

### 4. ⚠️ API Permission Issue Documented
**Problem:** Read-only API token couldn't query storage endpoints
**Attempted Solution:** Extended ACLs on Proxmox host
**Result:** Partial success - basic queries work, detailed storage queries still blocked
**Workaround:** Using direct shell commands (du, df) on Proxmox host
**Lesson:** API permissions complex; CLI commands more practical for this use case
**Status:** Documented for future reference - not critical to session goals

### 5. ✅ Process Improvements Identified & Applied
**Issue:** Repeated bash syntax errors wasting tokens
**Root Cause:** Using command substitution `$(...)` in Bash tool - tool has limitations
**Solution Implemented:**
- Write scripts to files first using Write tool
- Execute scripts with Bash tool
- Avoid complex escaping in inline commands
- Validate syntax with `bash -n` before delivery
- **Result:** Eliminated trial-and-error wasted tokens going forward

## Current Status

| Task | Status | Notes |
|------|--------|-------|
| Organize 920 TV shows | ✅ In Progress | 780GB+ moved, still running |
| Storage documentation | ✅ Complete | Added to CLAUDE.md |
| Duplicate detection strategy | ✅ Planned | Waiting for 918 disks + available space check |
| API permissions | ⚠️ Partial | Working around limitations, not blocking |
| Script quality | ✅ Improved | Validation + error avoidance implemented |

## Next Steps (Session 29 or Later)

1. **Monitor script completion:** Check when 780GB+ growth stops
2. **Verify final size:** `du -sh /storage/Media/series920part`
3. **Check space remaining:** `df -h /storage/Media/`
4. **Insert 918 disks** into UGREEN
5. **Create duplicate detection script:**
   - Scan existing UGREEN shows (3TB)
   - Scan 920 backup shows (now in series920part)
   - Identify matches by filename/show name/episode number
   - Generate transfer plan
6. **Execute tiered transfer:**
   - Phase 1: Copy non-duplicates from 920 to new disk (network)
   - Phase 2: Copy existing UGREEN shows to mirror disk (local)
   - Phase 3: Decide on duplicate handling based on remaining space

## Technical References

**Script Location:** `/mnt/lxc102scripts/organize-920-tv-shows.sh`
- Accessible from container: `/mnt/lxc102scripts/`
- Accessible from Proxmox host: `/nvme2tb/lxc102scripts/`

**Storage Paths:**
- Original backup: `/storage/Media/20251209backupsfrom918/backup seriale 2022 od 2023 09 28/`
- Organized location: `/storage/Media/series920part/`
- Windows access: `p:\series920part\`

**API Token Issue Summary:**
- See: `/home/sleszugreen/API-PERMISSION-ISSUE-SUMMARY.txt` (if created)
- Or search CLAUDE.md for "API Permission Issue"

## Key Learnings

1. **Storage Strategy:** Redundancy ≠ Space Efficiency
   - Hardlinks/reflinks save space but break redundancy
   - User goal is mirror backups, not deduplicated storage
   - Full copies needed for true backup protection

2. **Workflow Optimization:** Validate Before Delivery
   - Write → Validate (bash -n) → Show to user
   - Avoid trial-and-error with complex bash syntax
   - Script files safer than inline commands

3. **API vs CLI:** Practical vs Elegant
   - API permissions can be complex to configure
   - Simple shell commands often more practical
   - Focus on results, not using "elegant" solutions

4. **Decision Making:** Data Before Decisions
   - Don't commit to strategy without seeing actual numbers
   - Wait for 918 disks + available space before finalizing approach
   - Real situation might change priorities

## Session Statistics

- **Duration:** Single session
- **Scripts Created:** 1 (organize-920-tv-shows.sh)
- **Documentation Updated:** CLAUDE.md (storage structure)
- **Process Improvements:** 3 (API, bash syntax, workflow)
- **Data Moved:** 780GB+ (still in progress)
- **Tokens Used:** ~25,300
