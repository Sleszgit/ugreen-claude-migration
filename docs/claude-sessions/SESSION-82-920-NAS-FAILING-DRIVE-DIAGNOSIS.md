# Session 82: 920 NAS Failing Drive Diagnosis & Decommissioning Plan

**Date:** 4 Jan 2026
**Time:** 10:00 - 10:30
**Focus:** Identify which volume/data the failing 920 NAS drive belongs to, and plan decommissioning strategy

---

## Summary

Successfully identified the **failing 920 NAS drive** and mapped it to specific volumes/data. Confirmed decommissioning plan to redistribute data from failing volume to new Homelab mirror pool.

---

## 920 NAS Failing Drive Details

**Identified Failing Drive:**
- **SATA Port:** sata2 (Bay 2)
- **Model:** ST16000NE000-2RW103 (Seagate IronWolf Pro 16TB)
- **Serial Number:** ZL2LZPEV ← **FOR RMA**
- **Errors:** 3 UNC (Uncorrectable) + 4 ATA errors
- **Status:** FAILING

**Complete 920 NAS Drive Inventory:**
| SATA | Bay | Model | Capacity | Serial | Status | Errors |
|------|-----|-------|----------|--------|--------|--------|
| sata1 | 1 | ST16000NE000-2RW103 | 16TB | ZL2LZJ5P | ✅ Healthy | 0 |
| **sata2** | **2** | **ST16000NE000-2RW103** | **16TB** | **ZL2LZPEV** | **❌ FAILING** | **3 UNC + 4 ATA** |
| sata3 | 3 | ST20000NE000-3G5101 | 20TB | ZVT8N2ZV | ✅ Healthy | 0 |
| sata4 | 4 | ST20000NE000-3G5101 | 20TB | ZVT8N304 | ✅ Healthy | 0 |

---

## 920 NAS Volume & RAID Configuration

**Volume Discovery:**
```
/volume1 (18TB, 95% full) ← cachedev_1
  └── Seriale 2023 (TV Series)

/volume2 (14TB, 83% full) ← cachedev_0
  └── Filmy920 (Films)
```

**RAID Mapping (from /proc/mdstat):**
```
md3: raid1 [sata1p3 + sata2p3] = 15.6TB ≈ /volume2 (Filmy920)
md2: raid1 [sata3p3 + sata4p3] = 19.5TB ≈ /volume1 (Seriale 2023)
md1: raid1 [all 4 drives p2] = 2.1GB (system)
md0: raid1 [all 4 drives p1] = 2.5GB (system)
```

**Critical Finding:**
- **FAILING DRIVE (sata2) is in md3**
- **md3 contains /volume2 = FILMY920 (Films)**
- **Therefore: FILMY920 is AT RISK**

---

## Current Storage Inventory Across All Systems

### Films (4,485 total files)
| Location | Folder Structure | Files | Size | Status |
|----------|------------------|-------|------|--------|
| UGREEN | /storage/Media/Filmy920 | 2,328 | 8.4 TB | ✅ Safe |
| UGREEN | /storage/Media/Movies918 | 837 | 1.5 TB | ✅ Safe |
| Homelab | /WD10TB/Filmy920 | 1,320 | 3.1 TB | ✅ Safe |
| **TOTAL** | **15 folders** | **4,485** | **~13 TB** | — |

### TV Series (1,460+ shows)
| Location | Folder Count | Shows | Size | Status |
|----------|--------------|-------|------|--------|
| UGREEN | /seriale2023 | 1,092 | 13 TB | ✅ Safe |
| UGREEN | /storage/Media/series920part | 364 | 4.0 TB | ✅ Safe |
| UGREEN | /storage/Media/Series918 | 2 | 514 GB | ✅ Safe |
| Homelab | /WD10TB/918backup2512/07-tv-shows | 2 | 15 GB | ✅ Safe |
| **TOTAL** | **1,092+** | **1,460+** | **~17.5 TB** | — |

---

## Decommissioning Plan

**Phase 1: Extract Healthy Drives**
- Remove sata3 + sata4 (healthy md2 pool) from 920 NAS
- These drives contain SERIALE 2023 (TV Series) - currently safe

**Phase 2: Create Homelab Mirror Pool**
- Install sata3 + sata4 into Homelab
- Create new mirror pool from these 2 healthy drives
- This becomes redundant backup storage

**Phase 3: Redistribute Data**
- Move FILMY920 (at-risk films) from 920 NAS to new Homelab mirror pool
- Redistribute other films from UGREEN as needed
- Keep SERIALE 2023 on UGREEN or redistribute to new mirror pool

**Phase 4: Decommission 920 NAS**
- Send sata2 (ZL2LZPEV) for RMA with Seagate
- Keep sata1 as spare/backup
- Fully decommission 920 NAS once all data is evacuated

---

## Risk Analysis

**Immediate Risk:** FILMY920 on failing md3 pool
- 2,328 files (8.4 TB) from /storage/Media/Filmy920
- Single drive failure = data loss (only 2-drive raid1, already 1 failing)
- **Action Required:** Prioritize moving this data first

**Protected Data:**
- SERIALE 2023 on healthy md2 pool (sata3 + sata4) - NO RISK
- UGREEN storage - NO RISK (separate systems)
- Homelab storage - NO RISK (separate systems)

---

## Next Steps (User Decision Required)

1. **Immediate:** Back up FILMY920 from 920 NAS before drive failure cascades
2. **Plan:** Decide redistribution strategy for films/series across pools
3. **Execute:** Physical drive swap at Homelab
4. **Verify:** Test new mirror pool before decommissioning 920 NAS
5. **RMA:** Send failing drive (ZL2LZPEV) for replacement

---

## Commands Used

**Drive Inventory:**
```bash
ssh backup-user@192.168.40.20
smartctl -a /dev/sata1
smartctl -a /dev/sata2  # UNC errors detected
smartctl -a /dev/sata3
smartctl -a /dev/sata4
```

**Volume & RAID Discovery:**
```bash
df -h | grep volume
ls -1 /volume1/ /volume2/
cat /proc/mdstat
```

**Current Storage Inventory:**
```bash
ssh ugreen-host "find /seriale2023 -maxdepth 1 -type d | wc -l"
ssh ugreen-host "find /storage/Media/Filmy920 -type f | wc -l"
ssh homelab "find /WD10TB/Filmy920 -type f | wc -l"
```

---

## Files Referenced

- `/mnt/lxc102scripts/` - Bind mount for scripts accessible to both LXC 102 and Proxmox host
- `~/.claude/ENVIRONMENT.yaml` - Network topology reference
- `~/docs/claude-sessions/` - Session documentation location

---

**Status:** ✅ Complete - Ready for Phase 1 (drive extraction)
