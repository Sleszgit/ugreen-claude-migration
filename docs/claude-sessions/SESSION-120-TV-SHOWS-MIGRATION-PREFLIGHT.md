# Session 120: TV Shows Migration - Pre-Flight Status Check & Inventory

**Date:** 14 January 2026, ~14:30 CET
**Status:** ✅ COMPLETE - Pre-flight analysis done, migration plan ready

---

## Executive Summary

Conducted comprehensive pre-flight status check for data migration plan across UGREEN and Homelab systems. Located missing 1,094 TV show folders and verified current storage capacity. Migration plan blocked by insufficient free space on destination (Homelab).

---

## Tasks Completed

### ✅ Pre-Flight Status Check (Destination)

**Homelab (192.168.40.40):**
- `zfs list` verified datasets exist:
  - `Seagate-20TB-mirror/FilmsHomelab` - 3.06TB (root owned - needs chown)
  - `Seagate-20TB-mirror/SeriesHomelab` - 3.91T with 363 TV show folders (ugreen-homelab-ssh owned)
  - `Seagate-20TB-mirror/Movies918` - 1.47TB (already transferred)

**SSH Access:** ✅ Verified `sshadmin@192.168.40.40` is reachable and responsive

---

### ✅ Pre-Flight Status Check (Source)

**UGREEN (192.168.40.60):**
- Initial path `/storage/Media/series920part` NOT FOUND (doesn't exist)
- SSH connectivity to Homelab working via `sshadmin@192.168.40.40`

---

### ✅ Located ALL 1,094 Missing TV Shows

**Session 93 (Jan 5) reported:**
- 920 NAS: 1,436 total TV show folders
- UGREEN had split this as:
  - `/seriale2023/`: 1,091 folders
  - `/storage/Media/series920part/`: 363 folders

**Current Reality (Jan 14):**
- `/seriale2023/` is now EMPTY (4.0K only) - contents were moved
- `/storage/Media/series920part/` doesn't exist
- **FOUND:** `/SeriesUgreen` ZFS dataset contains **1,094 TV show folders** (13TB)

---

### ✅ Complete TV Shows Inventory

| Location | Count | Size | Owner | Status |
|----------|-------|------|-------|--------|
| `/SeriesUgreen` (UGREEN) | 1,094 | 13T | 1027:users | ⏳ Needs migration |
| `/storage/Media/Series918/TVshows918` (UGREEN) | 40 | 514GB | - | ⏳ Needs migration |
| `/Seagate-20TB-mirror/SeriesHomelab` (Homelab) | 363 | 4.0T | ugreen-homelab-ssh | ✅ Already on Homelab |
| **TOTAL** | **1,497** | **~17.5T** | - | - |

**Sample shows in /SeriesUgreen:** 11 22 63, 12 Monkeys, 1670, 1883, 19-2, 1990, 25 lat niewinności, 30 Rock, 3 body problem, 4 blocks, 666 Park Avenue, Ahsoka, etc.

---

### ✅ Storage Capacity Analysis

**UGREEN Free Space:**
| Pool | Total | Used | Free | Capacity |
|------|-------|------|------|----------|
| SeriesUgreen | 14.5T | 12.9T | **1.62T** | 88% ⚠️ |
| storage | 20T | 15.0T | **4.96T** | 75% ⚠️ |
| nvme2tb | 1.81T | 11.2G | **1.80T** | 0% ✅ |
| **TOTAL** | **36.3T** | **28.0T** | **~8.4T** | - |

**Homelab Free Space:**
| Pool | Total | Used | Free | Capacity |
|------|-------|------|------|----------|
| Seagate-20TB-mirror | 18.2T | 8.44T | **9.75T** | 46% ✅ |
| WD10TB | 9.09T | 4.28T | **4.81T** | 47% ✅ |
| **TOTAL** | **27.3T** | **12.7T** | **~14.6T** | - |

---

### ✅ Verified Folder Locations

**Movies918:**
- ✅ ON UGREEN: `/storage/Media/Movies918` (1.5TB)
- ✅ ON HOMELAB: `/Seagate-20TB-mirror/Movies918` (1.47TB) - **Already transferred**

**Series918:**
- ✅ ON UGREEN: `/storage/Media/Series918` (514GB, contains TVshows918 with 40 shows)
- ❌ NOT on Homelab

**Films918:**
- ❌ Does NOT exist (films are in Filmy920 on UGREEN and FilmsHomelab on Homelab)

---

## 🛑 Critical Finding: Insufficient Capacity for Full Migration

**Migration impact analysis:**

Migrating 1,094 shows (13TB from /SeriesUgreen):
- UGREEN after: 8.4T - 13T = **NEGATIVE** ❌
- Homelab after: 9.75T - 13T = **NEGATIVE** ❌

**Homelab cannot accommodate 13TB transfer - exceeds available capacity by ~3.25TB**

---

## SSH Key Status

From Session 118 findings:
- SSH key type: ed25519
- User: sleszugreen (non-root)
- Location: `~/.ssh/id_ed25519`
- Status: ✅ Working (verified Jan 13)
- Connected to: `sshadmin@homelab`

---

## Next Steps Required

**BEFORE migration can proceed:**

1. **Expand Homelab storage** - Add drives to Seagate-20TB-mirror pool
2. **OR delete/archive data on Homelab first** - Free ~3-4TB
3. **OR migrate in phases** - Transfer smaller batches

**Recommended sequence IF capacity resolved:**
1. Migrate 40 shows from Series918 (514GB) - Quick win
2. Migrate 1,094 shows from /SeriesUgreen (13TB) - Main batch

---

## Key Documentation

**Related Sessions:**
- Session 118: SSH Key Setup & Phase 1 Consolidation Script
- Session 93: 920 NAS Decommissioning - Data Verification Before Drive Removal
- Session 62: Final Summary and Data Safety (36TB TV shows from seriale2023 pool)

**Files Modified:**
- None (read-only investigation only)

---

## Session Statistics

- **Duration:** ~30 minutes
- **Systems checked:** UGREEN (192.168.40.60), Homelab (192.168.40.40), 920 NAS (192.168.40.20)
- **Folders located:** 1,094 TV shows in /SeriesUgreen
- **Capacity gaps identified:** 13TB missing on Homelab
- **SSH connections tested:** 5
- **ZFS pools queried:** 5

---

**Status:** Ready for next phase once storage capacity is resolved.
