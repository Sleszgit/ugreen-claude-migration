# Session 26 Dec 2025: Phase 2.5 Transfer - Live Execution

**Date:** 26 December 2025 (Evening)
**Status:** ✅ TRANSFER RUNNING - 4.07TB being copied to homelab
**Duration:** ~20-25 hours estimated
**Screen Session:** `phase2.5-transfer` (running on UGREEN host)

---

## EXECUTIVE SUMMARY

Successfully resolved SSH authentication issue and started Phase 2.5 transfer moving 4.07TB of 918 backups from UGREEN to homelab. Transfer started at 2025-12-25 21:16:27, running in screen session for persistence.

---

## CRITICAL INFORMATION - FOR FUTURE REFERENCE

### Exact Folders Being Transferred

**Source 1: `/storage/Media/20251209backupsfrom918/` (6 folders, ~192GB)**
```
1. Backup z DELL XPS 2024 11 01                    → 01-backup-dell-xps
2. Backup dokumenty z domowego 2023 07 14          → 02-backup-dokumenty-1
3. Backup drugie dokumenty z domowego 2023 07 14   → 03-backup-dokumenty-2
4. Backup pendrive 256 GB 2023 08 23               → 04-backup-pendrive
5. Zgrane ze starego dysku 2023 08 31              → 05-old-disk
6. Backup komputera prywatnego 2024 03 06          → 06-backup-komputer
```

**Source 2: `/storage/Media/20251220-volume3-archive/` (3 folders, ~3.88TB)**
```
7. TV shows serial outtakes                        → 07-tv-shows
8. __Backups to be copied                          → 08-backups-misc
9. 20221217                                        → 09-20221217
```

**NOT being transferred (user decision):**
- `backup seriale 2022` (3.6TB) - staying on UGREEN for now

### Target Location
- **Homelab Path:** `/WD10TB/918backup2512/`
- **Homelab User:** `sshadmin` (not root)
- **Homelab Host:** 192.168.40.40

---

## TRANSFER SCRIPT DETAILS

### Location
- **Container:** `/mnt/lxc102scripts/transfers/phase2.5-918backup-transfer.sh`
- **UGREEN Host:** `/nvme2tb/lxc102scripts/transfers/phase2.5-918backup-transfer.sh`
- **Both point to same file** (bind mount at 192.168.40.82 LXC 102)

### Command to Run (on UGREEN host)
```bash
# In screen session
screen -S phase2.5-transfer
bash /nvme2tb/lxc102scripts/transfers/phase2.5-918backup-transfer.sh

# To detach: Ctrl+A, D
# To reattach: screen -r phase2.5-transfer
```

### Script Features
- ✅ Automatic source folder verification
- ✅ SSH connectivity checks (30-second timeout)
- ✅ Target directory creation on homelab
- ✅ Per-folder rsync with progress tracking
- ✅ Checksums enabled (`-c` flag)
- ✅ Delete orphaned files on destination
- ✅ Comprehensive logging to `/home/sleszugreen/logs/phase2.5-transfer-*.log`
- ✅ User confirmation before transfer starts
- ✅ Supports `--dry-run` flag for testing

---

## SSH KEY SETUP - CRITICAL FOR FUTURE TRANSFERS

### Issue Identified (26 Dec 2025)

**Problem:** SSH worked from LXC 102 container but failed from UGREEN host
- Container used: `id_ed25519` key from `/home/sleszugreen/.ssh/id_ed25519`
- UGREEN host used: Different `id_ed25519` key from `/home/sleszugreen/.ssh/id_ed25519`

**Resolution:** Added UGREEN host's public key to homelab

### SSH Keys Authorized on Homelab (sshadmin)

**Key 1: LXC 102 Container (already existed)**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXeZF7Y9eHThfly/Scz6moHr0IFnLAee/QFeXZR8ImR ugreen-lxc102
```
Location: `/home/sshadmin/.ssh/authorized_keys:5`

**Key 2: UGREEN Host (added 26 Dec 2025)**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgq8rtR9vStPtlB5pF5HORQazQe+k2T9xxYILNJL+Qj sleszugreen@proxmox-host
```
Added via: `echo '...' >> ~/.ssh/authorized_keys`

### Why This Matters
- Each system (container vs Proxmox host) has different SSH keys in `/home/sleszugreen/.ssh/`
- Both need to be authorized on homelab for transfers to work
- Future transfers from either location require their respective keys

---

## TRANSFER MONITORING

### Check Progress
```bash
# From UGREEN host, attach to running session
screen -r phase2.5-transfer

# View log file
tail -f /home/sleszugreen/logs/phase2.5-transfer-20251225_*.log

# Check folder sizes on homelab after transfer
ssh sshadmin@192.168.40.40 'du -sh /WD10TB/918backup2512/*'
```

### Expected Timeline
- **Folder 1 (Backup z DELL XPS):** ~4GB, ~5-10 minutes
- **Folders 2-6:** ~188GB combined, ~2-3 hours
- **Folder 7 (TV shows):** ~15GB, ~30 minutes
- **Folders 8-9:** ~3.88TB, remaining 18-20 hours
- **Total:** 20-25 hours (network dependent)

### Storage Verification
After transfer completes, verify on homelab:
```bash
ssh sshadmin@192.168.40.40 'du -sh /WD10TB/918backup2512/ && df -h /WD10TB/'

# Expected result:
# /WD10TB/918backup2512/ should be ~4.07TB
# /WD10TB/ should show ~4.6TB used (51% of 9TB capacity)
```

---

## SESSION TIMELINE

### Issues Encountered & Resolutions

| Time | Issue | Root Cause | Resolution | Tokens Used |
|------|-------|-----------|-----------|------------|
| 21:06 | SSH timeout (5s) | Aggressive timeout | Increased to 30s | 500 |
| 21:08 | SSH failed on UGREEN | Different SSH key | Added UGREEN host key to homelab | 1,000 |
| 21:16 | Transfer started | N/A | ✅ Running in screen | 200 |

### Key Lessons Learned

1. **SSH Keys Are System-Specific**
   - Container and Proxmox host have different keys
   - Both need authorization on destination

2. **SSH Timeouts Need Tuning**
   - 5-second timeout too aggressive for remote connections
   - 30 seconds more reliable

3. **Script Error Output Must Be Visible**
   - Hiding stderr with `&>/dev/null` makes debugging impossible
   - Always show SSH error messages in scripts

4. **Documentation Gaps**
   - Previous sessions mentioned `/storage/Media/` paths but script creation didn't verify them
   - Exact folder names need to be in session docs for reuse

5. **Location Confusion**
   - Must always distinguish between:
     - Container (LXC 102, ugreen-ai-terminal, 192.168.40.82)
     - UGREEN host (192.168.40.60)
     - Homelab host (192.168.40.40)

---

## NEXT STEPS

### During Transfer
- Monitor progress periodically: `screen -r phase2.5-transfer`
- Check logs if issues occur: `/home/sleszugreen/logs/phase2.5-transfer-*.log`

### After Transfer Completes
1. Verify all 9 folders on homelab
2. Check disk usage on homelab matches expected
3. Compare file counts/checksums if needed
4. Document completion and results
5. Plan Phase 2 transfer (Filmy920 2022-2025, ~3.6TB)

### For Future Transfers
- Use this script for Phase 2 (Filmy920)
- Update folder paths as needed
- Both SSH keys already authorized on homelab
- Should run faster on subsequent transfers

---

## REFERENCE INFORMATION

### Network Details
- **UGREEN host:** 192.168.40.60
- **UGREEN container (LXC 102):** 192.168.40.82
- **Homelab host:** 192.168.40.40
- **All on same subnet:** 192.168.40.0/24

### SSH Configuration
- **Homelab user:** sshadmin (not root)
- **UGREEN user:** sleszugreen
- **SSH port:** 22 (standard)
- **Authentication:** Public key only (configured on homelab)

### Storage Details
- **UGREEN total storage:** 2TB ZFS (nvme2tb)
- **Homelab capacity:** 9TB WD10TB
- **After Phase 2.5:** ~4.6TB used (51%)
- **After Phase 2:** ~7.2TB used (81%)

---

## IMPORTANT REMINDERS FOR NEXT SESSION

1. **The exact folder names (9 folders listed above) MUST be referenced for any verification or troubleshooting**

2. **Both SSH keys (container + UGREEN host) are now authorized on homelab**

3. **Transfer is running in screen session** - check with:
   ```bash
   screen -r phase2.5-transfer
   ```

4. **Log file location:** `/home/sleszugreen/logs/phase2.5-transfer-20251225_210619.log`

5. **Target location:** `/WD10TB/918backup2512/`

6. **Do NOT start additional transfers until this one completes** - bandwidth limited

---

**Session Status:** LIVE TRANSFER IN PROGRESS
**Estimated Completion:** 26 Dec 2025, ~16:30-20:30 CET (depending on network speed)
**Last Updated:** 2025-12-26 21:16:27

