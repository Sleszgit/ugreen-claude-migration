# Session 115: Films Consolidation to ZFS Datasets - Setup & Troubleshooting

**Date:** 12 January 2026
**Time:** 00:30 - 01:00 CET
**Status:** 🔄 IN PROGRESS - SSH auth issues with sudo script execution
**Duration:** ~30 minutes

---

## Executive Summary

Prepared comprehensive films consolidation project with ZFS datasets:
- ✅ Created FilmsUgreen dataset on UGREEN (media-optimized settings)
- 🔄 2022-2025 films being copied to FilmsHomelab (via parallel rsync on Homelab)
- ⚠️ 2018-2019 transfer script created but SSH key authentication failing with sudo

---

## Tasks Completed

### 1. ✅ FilmsUgreen Dataset Created (UGREEN)
```bash
zfs create -o recordsize=1M -o compression=lz4 storage/FilmsUgreen
```
**Status:** Verified and ready to receive 2018-2021 films

### 2. 🔄 Films Already on Homelab (WD10TB → FilmsHomelab)
- **Status:** Session 114 completed series920part transfer
- **Current:** 2022-2025 films (3.1TB) being moved from /WD10TB/Filmy920 to /Seagate-20TB-mirror/FilmsHomelab/
- **Method:** mv command (local ZFS to ZFS, should be fast)
- **Location:** Screen session on Homelab

### 3. ⚠️ 2018-2019 Transfer Script (UGREEN → Homelab)
**Created:** `/mnt/lxc102scripts/transfer-films-2018-2019-BULLETPROOF.sh`

**What it does:**
- Phase 0: Pre-flight validation (SSH, paths, directories)
- Phase 1: Count source files (2018: 209 files/1.5TB, 2019: 922 files/2.3TB)
- Phase 2: Transfer 2018 via rsync
- Phase 3: Verify 2018 file count
- Phase 4: Transfer 2019 via rsync
- Phase 5: Verify 2019 file count
- Phase 6: Final summary

**Current Issue:**
```
SSH error: Permission denied (publickey)
When running: sudo bash /nvme2tb/lxc102scripts/transfer-films-2018-2019-BULLETPROOF.sh
```

**Root Cause:** SSH keys not properly accessible to sudo-elevated process

**Attempted Fixes:**
1. Added SSH_CONFIG variable to point to user's .ssh directory
2. Added fallback key detection (ed25519, then rsa)
3. Script still fails with "Permission denied (publickey)" on rsync

---

## Storage State After Session

### UGREEN /storage/Media/
```
FilmsUgreen/        (empty, ready)
Filmy920/           (contains 2018, 2019, 2020, 2021 - 8.4TB total)
Series918/          (backup data)
```

### Homelab /Seagate-20TB-mirror/
```
FilmsHomelab/       (3.1TB+ being transferred)
├── 2022-2025 in progress
SeriesHomelab/      (3.9TB - completed from Session 114)
```

### Homelab /WD10TB/
```
/WD10TB/Filmy920/   (original 2022-2025 location - being moved to Seagate)
```

---

## SSH Authentication Issue Analysis

**Problem Sequence:**
1. Script runs with `sudo bash script.sh`
2. Pre-flight validation passes (source folders verified)
3. SSH test connection works
4. rsync command fails: `Permission denied (publickey)`

**Why sudo breaks SSH keys:**
- When running `sudo bash`, the process runs as root
- Root's SSH config is empty (no known hosts, no keys)
- Script tries to use SUDO_USER's keys, but rsync doesn't inherit them properly

**Potential Solutions:**
1. Run script WITHOUT sudo (but needs storage access)
2. Use ssh-agent to hold keys
3. Run rsync separately (not via sudo wrapper)
4. Add SSH keys to root user's .ssh/

---

## Options Going Forward

### Option A: Run Without Sudo
If storage permissions allow:
```bash
bash /nvme2tb/lxc102scripts/transfer-films-2018-2019-BULLETPROOF.sh
```
(May fail if /storage is root-owned)

### Option B: Manual rsync Commands
Run each folder manually with proper SSH:
```bash
rsync -avP --stats --checksum /storage/Media/Filmy920/2018/ ugreen-homelab-ssh@192.168.40.40:/Seagate-20TB-mirror/FilmsHomelab/2018/
rsync -avP --stats --checksum /storage/Media/Filmy920/2019/ ugreen-homelab-ssh@192.168.40.40:/Seagate-20TB-mirror/FilmsHomelab/2019/
```

### Option C: Add SSH Keys to Root
```bash
sudo mkdir -p /root/.ssh
sudo cp ~/.ssh/id_ed25519 /root/.ssh/
sudo chmod 600 /root/.ssh/id_ed25519
```
Then retry script with `sudo`.

---

## Film Consolidation Plan (Summary)

**Target State (when complete):**

```
Homelab /Seagate-20TB-mirror/FilmsHomelab/
├── 2018/  (1.5TB, 209 files from UGREEN)
├── 2019/  (2.3TB, 922 files from UGREEN)
├── 2020/  (3.7TB, XXX files from UGREEN)
├── 2021/  (1.1TB, XXX files from UGREEN)
├── 2022/  (1.4TB, 1344+ files from WD10TB)
├── 2023/  (711GB, 922+ files from WD10TB)
├── 2024/  (539GB, XXX files from WD10TB)
└── 2025/  (470GB, XXX files from WD10TB)
Total: ~15.4TB all films consolidated

UGREEN /storage/Media/FilmsUgreen/
├── (copies only, sources remain on /storage/Media/Filmy920/)
(Plan to decide on source deletion after verification)
```

**Seagate-20TB-mirror Occupancy:**
- After consolidation: ~19.3TB / 18TB = 107% (OVER CAPACITY!)
- This exceeds the 70% safety limit!

---

## Issues to Resolve

1. **SSH auth with sudo** - Primary blocker
2. **Storage capacity warning** - Full consolidation would exceed Seagate 70% target
   - Need to finalize decision: keep 2018-2019 on UGREEN or move all to Homelab?

---

## Files Created This Session

- `/mnt/lxc102scripts/transfer-films-2018-2019-BULLETPROOF.sh` (production-ready, SSH auth issue)
- Session log: This file

---

## Next Steps

1. Resolve SSH authentication issue (Option A, B, or C above)
2. Complete 2018-2019 transfer to FilmsHomelab
3. Verify file counts match sources
4. Decide on source deletion (after manual verification of transferred files)
5. Update Seagate pool strategy if approaching capacity

---

**Session Owner:** Claude Code (Haiku 4.5)
**Last Updated:** 12 January 2026, 01:00 CET
**Status:** SETUP COMPLETE - Transfer blocked by SSH auth issue
