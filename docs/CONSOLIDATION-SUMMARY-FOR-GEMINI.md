# Films Consolidation Project - Current Situation Summary
**Date:** 12 January 2026, 06:10 AM CET
**Project Status:** Films being consolidated from multiple storage locations to Homelab Seagate mirror

---

## Executive Overview

**Objective:** Consolidate all film libraries (2018-2025) to a single ZFS dataset on Homelab Seagate-20TB-mirror

**Current Status:** 60% through consolidation
- ✅ 2022-2024 films transferred (2.7TB)
- 🔄 2025 films actively transferring (344GB remaining)
- ⏳ 2018-2021 films pending (8.6TB on UGREEN, blocked by SSH auth issue)

---

## Storage Situation - ACTUAL NUMBERS

### Seagate-20TB-mirror Pool (Homelab) - PRIMARY DESTINATION
```
Total capacity:    20 TB
Raw usable:        18.04 TB
Currently used:    6.65 TB  (36.9%)
Available free:    11.4 TB  (63.1%)
Health:            ONLINE (no errors)
```

**Safety Assessment:** Healthy. 63% free space exceeds 70% safety threshold.

---

## Current Consolidated Data on Seagate-20TB-mirror/FilmsHomelab

| Year | Status | Size | Location | Notes |
|------|--------|------|----------|-------|
| 2022 | ✅ DONE | 1.4 TB | Destination | Moved from /WD10TB/Filmy920/2022 |
| 2023 | ✅ DONE | 711 GB | Destination | Moved from /WD10TB/Filmy920/2023 |
| 2024 | ✅ DONE | 539 GB | Destination | Moved from /WD10TB/Filmy920/2024 |
| 2025 | 🔄 IN PROGRESS | 344 GB remaining | Source: /WD10TB/Filmy920 | Rsync w/ checksum & removal active since 06:05 AM |
| **Subtotal (2022-2025)** | | **2.8 TB destination** | From Homelab WD10TB pool |

---

## Remaining Data - NOT YET CONSOLIDATED

### UGREEN /storage/Media/Filmy920 (Source) - 8.4 TB
```
2018: 1.5 TB  (209 files)
2019: 2.3 TB  (922 files)
2020: 3.7 TB  (XXX files)
2021: 1.1 TB  (XXX files)
─────────────
Total: 8.6 TB pending transfer
```

**Current Issue:** SSH authentication blocking transfer script. Solution pending (Option A, B, or C from Session 115).

### UGREEN /storage/Media/FilmsUgreen (Empty Dataset)
- **Size:** 96K (empty)
- **Purpose:** Target location for 2018-2021 consolidation from Filmy920
- **Status:** Ready to receive data

---

## Seagate Pool Occupancy After Full Consolidation

**Current:** 6.65 TB used / 18.04 TB available

**Projected after 2018-2025 complete:**
```
Current used:      6.65 TB
+ 2025 remaining:  0.344 TB (currently transferring)
+ 2018 to move:    1.5 TB
+ 2019 to move:    2.3 TB
+ 2020 to move:    3.7 TB
+ 2021 to move:    1.1 TB
────────────────
Total projected:   15.694 TB
Available space:   18.04 TB
```

**Occupancy at full consolidation:** 86.9% ⚠️

**Safety Analysis:**
- Target threshold: 70% free (4.82 TB minimum)
- Projected free: 2.346 TB (13.1%)
- **Status:** EXCEEDS SAFETY THRESHOLD

---

## Transfer Mechanics

### Current Active Transfer (2025 Films)
**Command:**
```bash
rsync -avP --stats --checksum --remove-source-files \
  /WD10TB/Filmy920/2025/ \
  /Seagate-20TB-mirror/FilmsHomelab/2025/
```

**Process:**
- Started: 06:05 AM CET
- Status: Active (rsync PID running)
- Files remaining: 175 on source
- Method: Copy → Checksum verify → Remove source (atomic per file)

**Estimated completion:** 2-4 hours depending on I/O performance

### Pending Transfers (2018-2019)
**Script:** `/mnt/lxc102scripts/transfer-films-2018-2019-BULLETPROOF.sh`
**Status:** Created but blocked on SSH auth issue when using sudo
**Files:** 1,131 combined (209 + 922)
**Data:** 3.8 TB combined (1.5 + 2.3)

---

## Related Consolidation (Reference)

### SeriesHomelab (Already Completed)
- **Size:** 4.0 TB
- **Status:** Fully consolidated on Seagate-20TB-mirror/SeriesHomelab
- **Method:** Similar rsync consolidation from Homelab sources

---

## Blockers & Issues

### 1. SSH Authentication with Sudo (BLOCKING 2018-2019 transfer)
**Problem:** Transfer script fails with `Permission denied (publickey)` when run with sudo
**Options:**
- A: Run script without sudo (if permissions allow)
- B: Manual rsync commands without sudo wrapper
- C: Copy SSH keys to root's .ssh directory
**Priority:** High - blocks 8.6 TB transfer

### 2. Pool Capacity Warning
**Concern:** Full consolidation approaches 87% occupancy (exceeds 70% target)
**Options:**
- Accept higher occupancy for film consolidation phase
- Implement tiering (older films stay on UGREEN FilmsUgreen)
- Delete sources after verification
**Priority:** Medium - operational, not critical

---

## Decision Points for Gemini Analysis

1. **Should we resolve SSH auth issue (Option A, B, or C)?**
   - Which option is safest and most maintainable?

2. **Is 87% occupancy on Seagate acceptable for film consolidation?**
   - Or should we keep 2018-2019 on UGREEN FilmsUgreen instead?

3. **What's the optimal rsync strategy for 8.6 TB of older films?**
   - Parallel transfers for speed?
   - Sequential to minimize I/O contention?

4. **Source deletion policy after consolidation:**
   - Delete immediately after checksum verification?
   - Keep 48h before deleting (safety window)?
   - Manual verification before deletion?

---

## Files & References

**Session documentation:** `/home/sleszugreen/docs/claude-sessions/SESSION-115-FILMS-CONSOLIDATION-SETUP.md`
**Transfer script:** `/mnt/lxc102scripts/transfer-films-2018-2019-BULLETPROOF.sh` (ready, needs SSH fix)
**Monitoring:** `ssh homelab "screen -ls"` shows `films-2025-transfer` session

---

**Prepared by:** Claude Code (Haiku 4.5)
**For:** Gemini Pro CLI analysis and recommendations
