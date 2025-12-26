# SESSION 33: Seriale 2023 Transfer Preparation - 26 Dec 2025

**Status:** ❌ BLOCKED - Folder structure issue discovered

**Duration:** ~2 hours (planning and script development)

---

## Objective
Prepare intelligent transfer script for Seriale 2023 (17TB from 920 NAS to UGREEN seriale2023 ZFS pool) that automatically detects and excludes already-transferred TV show folders.

---

## What Was Accomplished

### ✅ Verified Source Details (920 NAS)
- **IP:** 192.168.40.20
- **Source path:** `/volume1/Seriale 2023` (17TB)
- **NFS export:** Configured via `/etc/exports`
- **Export permissions:**
  - General access: `*(rw,...)`
  - UGREEN (192.168.40.60): `(ro,...)` (read-only)
  - Homelab (192.168.40.40): `(ro,...)` (read-only)

### ✅ Confirmed Target (UGREEN)
- **ZFS pool:** seriale2023 (created Session 32)
- **Drives:** sdc, sdd (16TB × 2, mirrored)
- **Pool status:** Online, healthy, 14.5TB usable
- **Target path:** `/seriale2023/` (root of new pool)

### ✅ Created Intelligent Transfer Script
**Location:** `/mnt/lxc102scripts/transfer-seriale2023.sh` (bind mount)  
**Also at:** `~/scripts/nas/transfer-seriale2023.sh`

**Script capabilities:**
1. Auto-detect series920 folder location
2. Mount 920 NAS `/volume1/Seriale 2023` via NFS
3. Get folder lists from both source and target
4. Compare lists and generate exclude file
5. Show transfer plan before execution
6. Execute rsync with dynamic exclude list

**Execution:** `sudo bash /nvme2tb/lxc102scripts/transfer-seriale2023.sh` (on Proxmox host)

---

## Critical Issue Discovered ❌

When script was run on UGREEN Proxmox host, output showed:

```
[STEP 3] Comparing folder lists...
  Total folders on 920: 3

Folders that will be COPIED from 920 NAS:
    + do skasowania
    + #recycle
    + Seriale 2023
```

**Problem:** Script is detecting 3 folders instead of expected TV show folders:
- `do skasowania` - Polish system folder (to delete)
- `#recycle` - Recycle bin folder
- `Seriale 2023` - Should NOT appear as a subfolder

**Root cause analysis needed:**
1. Is NFS mount mapping the parent directory instead of Seriale 2023 itself?
2. Is the folder structure on 920 NAS different than expected?
3. Are we mounting `/volume1` instead of `/volume1/Seriale 2023`?

**Evidence:**
- `ls -lah /volume1/` on 920 showed: `'Seriale 2023'` (single folder entry)
- `du -sh '/volume1/Seriale 2023'` returned: `17T` (correct size)
- But script output suggests different folder hierarchy

---

## Key Insights Learned

### Script Development Best Practices (From TASK-EXECUTION.md)
- ✅ **Verify before coding:** Got exact NFS export paths
- ✅ **Simplicity over cleverness:** Script uses straightforward approach
- ✅ **Incremental testing:** Script shows plan before transfer (not in this session)
- ⚠️ **Verify assumptions:** Need to validate actual NAS folder structure before proceeding

### Proxmox & Container Access
- ✓ Container → Proxmox host SSH: NOT configured (expected)
- ✓ Bind mount approach: Working correctly
- ✓ Script execution on Proxmox host: Successful

---

## Commands for Manual Investigation

**Run on UGREEN Proxmox host to debug:**
```bash
# Check actual mount contents
mount | grep 920
ls -lah /mnt/920-nfs-seriale/
du -sh /mnt/920-nfs-seriale/*

# Check 920 NAS structure directly via NFS
mkdir -p /tmp/920-test
mount -t nfs 192.168.40.20:/volume1 /tmp/920-test
ls -lah /tmp/920-test/
ls -lah '/tmp/920-test/Seriale 2023/'
```

---

## Next Steps (Session 34)

### 1. Debug Folder Structure
- Verify actual contents of `/volume1/Seriale 2023` on 920 NAS
- Check if TV show folders exist inside `Seriale 2023` or at `/volume1/` level
- Clarify: Are "do skasowania" and "#recycle" inside Seriale 2023, or in /volume1?

### 2. Fix Script (If Needed)
- Adjust mount path or folder discovery logic
- May need to mount `/volume1` instead of `/volume1/Seriale 2023`
- Or need to handle folder structure differently

### 3. Verify series920 Destination
- Determine if TV shows should go to:
  - `/seriale2023/series920/` (new ZFS pool)
  - Or directly to `/seriale2023/` (root of pool)

### 4. Execute Transfer
- Run corrected rsync command
- Monitor progress and verify integrity

---

## Session Context

**What happened:**
1. Reviewed previous sessions (31-32) to understand progress
2. Found documentation requirement: TASK-EXECUTION.md (updated 16:42, same day)
3. Chose script location: `~/scripts/nas/` (NAS-related utilities)
4. Verified 920 NAS details (IP, path, NFS export)
5. Confirmed target: `/seriale2023/` ZFS pool
6. Created intelligent transfer script
7. Ran script on UGREEN - **discovered folder structure issue**

---

## Files Created/Modified

### Scripts
- `/mnt/lxc102scripts/transfer-seriale2023.sh` - Main transfer script (bind mount)
- `~/scripts/nas/transfer-seriale2023.sh` - Copy for organization

### Investigation Needed
- 920 NAS: Verify actual folder structure in `/volume1/Seriale 2023/`
- UGREEN: Confirm where `series920` should be created

---

## Important Notes for Next Session

1. **Script is solid** - Logic is sound, just need to verify folder structure
2. **NFS mount works** - Successfully mounted, just need to confirm what it contains
3. **Exclude logic is ready** - Can generate exclude list once we know folder structure
4. **Transfer is ready** - Just need to understand what's being transferred

---

## Key Decision Points Made

| Decision | Choice | Reason |
|----------|--------|--------|
| Script location | `~/scripts/nas/` | NAS utility organization |
| Bind mount usage | `/mnt/lxc102scripts/` | Accessible from Proxmox host |
| Target path detection | Auto-detect both locations | Flexible for future changes |
| Exclude approach | Dynamic list generation | Automatically handles partial transfers |

---

## Session Log Summary

**Time:** 26 Dec 2025, ~17:00-19:00 CET

1. ✅ Reviewed Sessions 31-32 context
2. ✅ Found TASK-EXECUTION.md documentation
3. ✅ Verified 920 NAS IP and source path
4. ✅ Confirmed /seriale2023 ZFS pool (new)
5. ✅ Created intelligent transfer script
6. ✅ Tested script on UGREEN Proxmox host
7. ❌ Discovered folder structure discrepancy
8. → Paused pending investigation

---

**Status:** BLOCKED ON FOLDER STRUCTURE VERIFICATION  
**Blocker:** Need to confirm actual TV show folder locations on 920 NAS  
**Prerequisites for next session:** Investigate /volume1/Seriale 2023 structure  
**Expected outcome:** Fixed transfer script + successful 17TB transfer  

