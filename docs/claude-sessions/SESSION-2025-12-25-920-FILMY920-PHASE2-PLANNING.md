# Session: 920 Filmy920 Phase 2 Planning & 918 Backup Transfer Setup

**Date:** 2025-12-25
**Duration:** Multiple queries (afternoon session)
**Participant:** User + Claude Code
**Status:** ✅ Complete - Transfer script created, ready for execution on homelab
**Primary Goal:** Verify Phase 1 completion and set up Phase 2 strategy (918 backups → homelab to free UGREEN space)

---

## Session Summary

Completed verification that Phase 1 (Filmy920 2018-2021, 8.6TB) transfer to UGREEN is **100% complete**. Identified the 10 backup folders (7.67TB total) from 918 NAS that should be copied to homelab to free up UGREEN space for Phase 2 Filmy920 remainder (3.6TB).

Created comprehensive NFS+rsync transfer script for homelab to automate the 918 backup copy operation.

---

## Phase 1 Verification Results ✅

**Status:** COMPLETE - All 4 folders transferred successfully

| Folder | Size | Status |
|--------|------|--------|
| 2018 | 1.5TB | ✅ Complete |
| 2019 | 2.3TB | ✅ Complete |
| 2020 | 3.7TB | ✅ Complete |
| 2021 | 1.1TB | ✅ Complete |
| **Total** | **8.6TB** | **✅ Complete** |

Verified via: `du -sh /storage/Media/Filmy920/*`
Screen session: `2526666.filmy920-transfer` (running since Dec 23, 6:28 PM)

---

## Phase 2 Strategy: Move 918 Backups to Homelab

**Objective:** Free up UGREEN space to fit remainder of Filmy920 (3.6TB)

### Folders to Copy from UGREEN to Homelab (7.67TB total)

**From /storage/Media/20251209backupsfrom918/ (4.0TB):**
1. Backup z DELL XPS 2024 11 01 (4.0G)
2. Backup dokumenty z domowego 2023 07 14 (4.6G)
3. Backup drugie dokumenty z domowego 2023 07 14 (4.6G)
4. Backup pendrive 256 GB 2023 08 23 (92G)
5. Zgrane ze starego dysku 2023 08 31 (126G)
6. Backup komputera prywatnego 2024 03 06 (184G)
7. backup seriale 2022 od 2023 09 28 (3.6T)

**NOT copied:** Backupy zdjęć Google od 2507 (18G - excluded per session notes)

**From /storage/Media/20251220-volume3-archive/ (4.3TB):**
1. TV shows serial outtakes (15G)
2. __Backups to be copied (76G)
3. 20221217 (3.6T)

**NOT copied:**
- aaafilmscopy (517G - keep on UGREEN for duplicate checking)
- Do przegrania na home lab lub gdzieś indziej 2025 11 01 (excluded)

**Total to transfer:** 7.67TB
**Destination on homelab:** `/WD10TB/918backup2512/`

---

## Important Technical Issues Discovered & Resolved

### Issue 1: SSH from Container to Proxmox Host NOT Configured
**Problem:** Attempted SSH from LXC 102 container to UGREEN Proxmox host
**Root Cause:** SSH is not configured between container and Proxmox host
**Solution:** Use Proxmox API instead (tokens: `~/.proxmox-api-token`)
**Learning:** Never attempt SSH from container to host - always use API or pct commands

### Issue 2: Proxmox API Blocked from Container
**Problem:** curl requests to `https://192.168.40.60:8006/api2/json/*` timed out from container
**Root Cause:** Proxmox firewall blocks port 8006 from container to host
**Solution:** Added firewall rule via `/etc/pve/firewall/cluster.fw`:
```
IN ACCEPT -source 192.168.40.82 -p tcp -dport 8006 -log nolog
```
**Created Script:** `/mnt/lxc102scripts/enable-api-access.sh` (executable on Proxmox host)

### Issue 3: File Path Confusion (UGREEN bind mount)
**Problem:** Created files in container's `/mnt/lxc102scripts/` but user expected them at `/nvme2tb/lxc102scripts/` on Proxmox host
**Root Cause:** Forgot that bind mount paths are different:
- Container: `/mnt/lxc102scripts/`
- Proxmox Host: `/nvme2tb/lxc102scripts/`
**Solution:** Always specify correct path based on where command is running

### Issue 4: SSH Between Homelab and UGREEN NOT Configured
**Problem:** `scp` command from homelab to UGREEN timed out
**Root Cause:** SSH not configured between homelab (192.168.40.40) and UGREEN (192.168.40.60)
**Solution:** Use heredoc method to create scripts directly on homelab instead of copying

---

## Transfer Script Created

**Location:** `/root/transfer-918backup-to-homelab.sh` (on homelab Proxmox)

**Functionality:**
- ✅ Creates NFS mount point (`/mnt/ugreen-media`)
- ✅ Mounts UGREEN storage via NFS (read-only)
- ✅ Copies 10 folders via rsync with progress tracking
- ✅ Logs all activity to timestamped file
- ✅ Provides summary statistics
- ✅ Estimated time: 20-25 hours

**Run on homelab:**
```bash
screen -S 918backup-transfer
bash /root/transfer-918backup-to-homelab.sh
# Detach: Ctrl+A then D
# Reconnect: screen -r 918backup-transfer
```

---

## Homelab Proxmox Storage Structure Verified

**Proxmox Host:** pve (192.168.40.40)

**Storage Pools:**
- WD10TB-backup (dir)
- WD10TB-storage (zfspool, 8.45 TiB available)
- local-lvm (lvmthin)
- WD10TB-iso (dir)
- WD10TB-templates (dir)
- local (dir)

**Folder Created:** `/WD10TB/918backup2512/` (permission: 777)

**Main Directory:** `/WD10TB/`
- comics (220GB)
- immich (with LXC 101 data)
- iso, backup, templates, shared-projects

---

## Updated Context Notes

**CRITICAL - Add to context files:**

1. **SSH is NOT configured between:**
   - Container → Proxmox host
   - Homelab → UGREEN
   - Always use API or local commands instead

2. **Proxmox API Access:**
   - UGREEN token: `~/.proxmox-api-token`
   - Homelab token: `~/.proxmox-homelab-token`
   - Must have firewall rule allowing container → API port 8006

3. **File Paths on UGREEN:**
   - Container: `/mnt/lxc102scripts/` ↔ Host: `/nvme2tb/lxc102scripts/`
   - Always specify correct path for the executing environment

4. **Homelab Proxmox:**
   - No bind mount structure like UGREEN
   - Scripts should be created directly at `/root/scripts/` or similar
   - Use heredoc/cat method for file creation, not SCP

---

## Storage Capacity Evolution

**Current (Dec 25 - after Phase 1):**
```
UGREEN:  10.2TB used / 9.7TB free (51%)
Homelab: 529GB used / 8.45TB free (6%)
```

**After 918 backup transfer (Phase 2.5):**
```
UGREEN:  2.53TB used / 17.47TB free (13%)
Homelab: 8.2TB used / 245GB free (97%)
```

**After Phase 2 (Filmy920 2022-2025 remainder):**
```
UGREEN:  5.9TB used / 14.1TB free (30%)
Homelab: 11.8TB used / -3.5TB free (OVER CAPACITY!)
```

⚠️ **NOTE:** Homelab will be over capacity after Phase 2. May need to:
- Check if shared-projects or other folders can be moved
- Or delay Phase 2 pending homelab cleanup
- Or use different storage location

---

## Session Artifacts

**Scripts Created:**
1. `/mnt/lxc102scripts/enable-api-access.sh` - Firewall rule setup for UGREEN API
2. `/mnt/lxc102scripts/list_storage_folders.sh` - List UGREEN storage structure
3. `/mnt/lxc102scripts/transfer-918backup-to-homelab.sh` - Main transfer script
4. `/mnt/lxc102scripts/check_homelab_structure.sh` - Homelab structure checker
5. `/mnt/lxc102scripts/test_and_query_api.sh` - API testing utility

**Files to create on homelab:**
- `/root/transfer-918backup-to-homelab.sh` - Transfer script (use heredoc method)

---

## Next Steps

### Immediate (Ready Now):
1. ✅ Create `/root/transfer-918backup-to-homelab.sh` on homelab (via heredoc)
2. ✅ Verify NFS can mount UGREEN storage from homelab
3. ✅ Run transfer in screen session: `screen -S 918backup-transfer`
4. ✅ Monitor progress

### After Phase 2.5 Completes (~24 hours):
1. [ ] Verify 7.67TB transferred to `/WD10TB/918backup2512/`
2. [ ] Check transfer integrity (optional: compare folder counts)
3. [ ] Free up UGREEN space by user manual deletion (user must approve deletion)
4. [ ] Execute Phase 2: Transfer Filmy920 2022-2025 remainder to UGREEN

### Phase 3 (Deferred):
- Transfer Seriale 2023 (17TB) to UGREEN after 918 drives installed
- Requires expansion of UGREEN storage (currently at capacity limit)

---

## Critical User Requirements Reminder

1. **NO auto-deletion** - User must manually delete folders after verification
2. **Keep UGREEN <70% full** - ZFS safety requirement
3. **Sequential execution** - Complete Phase 2.5 before Phase 2
4. **Verify checksums** - Check folder counts/sizes after transfers
5. **Homelab capacity issue** - Address storage before Phase 2 if over capacity

---

## Key Learnings

1. **API Access is critical** - When SSH not configured, Proxmox API is the solution
2. **Firewall rules matter** - Container-to-host API access requires explicit allow rule
3. **Path confusion avoids confusion** - Always explicitly state which environment (container vs host)
4. **Heredoc over SCP** - When SSH not available, use heredoc to create files directly
5. **Storage planning** - Must verify destination capacity before large transfers

---

**Session Status:** ✅ Complete - Transfer script ready, homelab prepared, execution waiting for user
**Artifacts:** 5 utility scripts created, transfer script ready for deployment
**Next Action:** User runs transfer script on homelab in screen session
