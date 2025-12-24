# Session: Phase 3 Planning - Smart Storage Rebalancing Strategy

**Date:** 2025-12-24
**Duration:** Multiple queries/discussion
**Participant:** User + Claude Code
**Status:** ✅ Complete - Plan approved and ready for execution
**Primary Goal:** Plan Phase 3 (Seriale 2023 transfer) with optimal storage utilization

---

## Session Summary

User and Claude engaged in comprehensive planning for Phase 3 (Seriale 2023 transfer from 920 NAS). Through iterative discussion, discovered a more efficient storage strategy that:

1. **Eliminates immediate need for hardware expansion** on UGREEN
2. **Uses existing Homelab capacity** for 918 backup content
3. **Keeps UGREEN at healthy 56% usage** (well under 70% target)
4. **Maintains sequential execution** to avoid HDD stress
5. **Defers 918 drive installation** until later (Phase 3)

---

## Key Decisions Made

### Storage Strategy: Option B (Split at Folder Boundaries)

**Original Plan:** Install 918 drives immediately to UGREEN
- **Problem:** Wouldn't have time before user needs space

**User's Better Idea:**
- Move 918 backup content (7.67TB) from UGREEN → Homelab
- This frees up 17.47TB on UGREEN
- Fit ALL Filmy920 (13TB) on UGREEN without expansion
- Keep UGREEN <70% full (achieves 56%)

**Result:**
- Phase 1: Filmy920 (2018-2021) → UGREEN (8.6TB)
- Phase 2.5: 918 backups → Homelab (7.67TB)
- Phase 2: Filmy920 (2022-2025) → Homelab (3.6TB)
- Phase 3: Deferred - Seriale 2023 → UGREEN (requires 918 drive expansion)

### Critical User Requirements

1. **NO Auto-Deletion** ❌
   - User will manually delete folders
   - Claude verifies checksums only
   - No automatic file removal under any circumstances

2. **Storage Targets** ✅
   - Keep UGREEN <70% full (ZFS requirement)
   - Plan achieves 56% after Phase 2
   - Leaves room for growth

3. **Sequential Execution** ✅
   - No parallel transfers to reduce HDD stress
   - Wait for Phase 1 → do Phase 2.5 → do Phase 2 → do Phase 3

4. **No UGREEN→Homelab SSH** ✅
   - User has desktop SSH to both devices
   - Will use desktop or NFS for transfers
   - Avoid setting up direct container links

5. **Duplicate Checking** 📋
   - Script to find duplicates: Filmy920 vs aaafilmscopy (517GB)
   - Noted for future session (not created yet)

---

## Technical Discoveries

### RAID Drive Stress Analysis

**Why 95% full = physical damage:**
- 10-15x more seeking (head wear)
- 5-10°C temperature increase
- 3-4x write amplification
- Ages drives 3-4x faster than normal

**Your 920 NAS reality:**
- Volume 1 (95% full): Running 6-8 years of wear in just 2.2 years
- RAID rebuild impossible if drive fails (insufficient space)
- System instability risk

### Safe RAID Capacity Levels

**General industry standards:**
- RAID1 (Mirror): Safe max 80%, target <70%
- RAID5/6: Safe max 70-75%
- **ZFS (stricter):** Safe max 75%, recommend <70%

**Your targets:**
- UGREEN (ZFS): <70% = 14TB used max
- After Phase 2: 11.13TB (56%) ✅ Optimal

### 918 NAS Drive Configuration Correction

**User caught important error:**
- Planned to use 16TB + 14TB (mixed sizes)
- Actual available: 2x 16TB (were mirrored in 918)
- Better solution: Use matching drives

**Why matching is better:**
- ✅ No wasted space (16TB vs 16TB, not 16TB vs 14TB)
- ✅ Already proven to work together
- ✅ Same age, same model
- ✅ Proper RAID1 pair

---

## Important Clarifications

### Capacity Calculations Fixed

**User corrected error:** "78% used" vs "22% used"
- Initial statement: "22% used" (incorrect)
- Correction: 78% USED, 22% FREE
- UGREEN after Phase 2: 15.53TB / 20TB = 78%
- Still safe for RAID1 but close to ZFS limit

### Critical Error Prevention

**Absolute rule established:** I WILL NOT DELETE FILES
- User must manually delete after verification
- I only report checksum results
- User has complete control of deletions

---

## Timeline Overview

| Phase | Content | Duration | Timeframe |
|-------|---------|----------|-----------|
| Phase 1 | Filmy920 (2018-2021) → UGREEN | ~30 hours | Dec 23-25 |
| Phase 2.5 | 918 backups → Homelab | ~20 hours | Dec 25-26 |
| Verify | User verification | ~1 day | Dec 26-27 |
| Phase 2 | Filmy920 (2022-2025) → Homelab | ~12 hours | Dec 27 |
| **Total** | **Phases 1-2 complete** | **~3-4 days** | **Dec 23-27** |
| Phase 3 | Deferred (Seriale 2023) | TBD | Later |

---

## Folder Inventory (UGREEN /storage/Media)

**Folders to stay on UGREEN:**
1. Series918 (514GB) - Existing 918 content
2. Movies918 (1.5TB) - Existing 918 content
3. Filmy920 (1.8TB) - Phase 1 in progress
4. ~~20251209backupsfrom918 (4.0TB)~~ → Moving to Homelab
5. ~~20251220-volume3-archive (4.3TB)~~ → Moving to Homelab

**Details of folders moving to Homelab:**

**Folder 4: 20251209backupsfrom918 (4.0TB) - Moving 3.98TB**
1. 4.0G - Backup z DELL XPS 2024 11 01
2. 4.6G - Backup dokumenty z domowego 2023 07 14
3. 4.6G - Backup drugie dokumenty z domowego 2023 07 14
4. ~~18G - Backupy zdjęć Google od 2507~~ EXCLUDING
5. 92G - Backup pendrive 256 GB 2023 08 23
6. 126G - Zgrane ze starego dysku 2023 08 31
7. 184G - Backup komputera prywatnego 2024 03 06
8. 3.6T - backup seriale 2022 od 2023 09 28

**Folder 5: 20251220-volume3-archive (4.3TB) - Moving 3.69TB (items 1, 2, 5)**
1. 15G - TV shows serial outtakes
2. 76G - __Backups to be copied
3. ~~166G - Do przegrania na home lab~~ (not included)
4. ~~517G - aaafilmscopy~~ (keep for duplicate checking)
5. 3.6T - 20221217

---

## Storage Capacity Evolution

**Current (Dec 24):**
```
UGREEN:   10.2TB used / 9.7TB free (51%)
Homelab:  0.53TB used / 8.5TB free (3%)
920 V1:   17TB used / 962MB free (95% CRITICAL)
920 V2:   13TB used / 2TB free (87% CRITICAL)
```

**After Phase 2.5 (Rebalancing):**
```
UGREEN:   2.53TB used / 17.47TB free (13%)
Homelab:  8.2TB used / 9.8TB free (46%)
```

**After Phase 2 (All Filmy920 Done):**
```
UGREEN:   11.13TB used / 8.87TB free (56%) ✅ Optimal
Homelab:  11.8TB used / 6.2TB free (66%) ✅ Healthy
920 V2:   0TB used / 14TB free (FREED!)
```

**Future After Phase 3 (With 918 Drives):**
```
UGREEN:   28TB used / 8TB free (78%) - Over capacity slightly
Homelab:  12TB used / 6TB free (67%)
920 V1:   0TB used / 18TB free (FREED!)
```

---

## Plan Documentation

**Location:** `/home/sleszugreen/.claude/plans/soft-sparking-scroll.md`

**Contents:**
- Detailed execution phases (1, 2.5, 2, 3)
- Storage capacity tables
- Risk assessment
- Timeline estimates
- Critical user requirements
- Drive allocation strategy

---

## Questions for Future Sessions

1. **Transfer method for Phase 2.5/2:** NFS mount or desktop-mediated rsync?
2. **Homelab destination path:** Exact mount point for WD10TB pool?
3. **Third 918 drive (14TB):** What to do with it? (Homelab or spare?)
4. **ZFS Config for Phase 3:** Option A (separate pools) or Option B (expand)?
5. **Duplicate checking script:** Criteria for identifying duplicates (size, hash, name)?

---

## Session Notes

### What Went Well ✅
- User provided excellent corrections (matching drives, 70% target)
- Identified a smarter storage strategy through discussion
- Clear user requirements established
- Plan optimizes space without immediate hardware work

### Learning Points 📚
- RAID capacity stress: Hidden but significant hardware impact
- ZFS stricter than RAID1: Aim for <70% not just <80%
- User verification critical: Never auto-delete, always checksum verify
- Matching drive pairs better than mixed sizes

### Next Session Prep 📋
- Monitor Phase 1 completion (Dec 25 AM)
- Prepare Phase 2.5 transfer scripts
- Create checksum verification tool
- Determine NFS vs desktop transfer method

---

## Commit Message for This Session

```
Plan Phase 3: Smart storage rebalancing and Seriale 2023 transfer strategy

Analyzed optimal storage utilization and determined that moving 918 backup
content (7.67TB) to Homelab before Phase 2 allows ALL Filmy920 (13TB) to fit
on UGREEN while maintaining 56% usage (well under 70% ZFS safety target).

Key decisions:
- Option B: Split Filmy920 at folder boundaries
- Sequential execution to minimize HDD stress
- Defer 918 drive installation until Phase 3 (Seriale transfer)
- User manual deletion only (no auto-delete)
- Keep UGREEN <70% full for ZFS health

Timeline: Phases 1-2 complete by Dec 27, 2025
Phase 3: Deferred until later when user ready for drive expansion

Storage evolution:
- Current: UGREEN 51%, Homelab 3%, 920 V1 95% (critical)
- After Phase 2: UGREEN 56%, Homelab 66%, 920 V2 0% (freed)
- Future: UGREEN 78%, Homelab 67%, 920 V1 0% (freed)
```

---

**Session Status:** ✅ Complete - Plan approved and documented
**Artifacts:** Plan file + Session notes
**Next Action:** Monitor Phase 1 completion, prepare Phase 2.5 execution
