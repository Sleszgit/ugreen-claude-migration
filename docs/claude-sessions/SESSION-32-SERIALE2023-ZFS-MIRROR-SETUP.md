# SESSION 32: Seriale 2023 ZFS Mirror Setup - 26 Dec 2025

**Status:** ✅ COMPLETE - ZFS mirror pool created, ready for bind mount and transfer

**Duration:** ~1 hour (including safety verification)

---

## Objective
Set up 2×16TB IronWolf Pro drives (from decommissioned 918 NAS) as ZFS mirror pool for Seriale 2023 transfer (17TB from 920 NAS to UGREEN).

---

## What Was Accomplished

### ✅ Drive Verification (Critical Safety Checks)
- **Confirmed drives:** sdc and sdd (both 14.6TB ST16000NE000-2RW - IronWolf Pro 16TB)
- **Data status verified:** Hexdump showed all zeros + EFI partition metadata only
- **Historical verification:** Checked SESSION-11-918-NAS-EMPTY-VERIFICATION.md confirming 918 NAS was completely cleared (only 8 KB Synology system files remain)
- **Safety confirmation:** Existing storage pool (20TB, sda+sdb) completely untouched

### ✅ Partition Table Wipe
```bash
sudo /usr/sbin/sgdisk --zap-all /dev/sdc
sudo /usr/sbin/sgdisk --zap-all /dev/sdd
# Output: "GPT data structures destroyed!"
```

### ✅ ZFS Mirror Pool Created
```bash
sudo zpool create -f seriale2023 mirror /dev/sdc /dev/sdd
```

**Pool Status:**
```
NAME          SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
seriale2023  14.5T   504K  14.5T        -         -     0%     0%  1.00x    ONLINE  -
```

**Detailed Status:**
```
pool: seriale2023
 state: ONLINE
config:
        NAME         STATE     READ WRITE CKSUM
        seriale2023  ONLINE       0     0     0
          mirror-0   ONLINE       0     0     0
            sdc      ONLINE       0     0     0
            sdd      ONLINE       0     0     0
errors: No known data errors
```

---

## Current State - All Pools

```
NAME          SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
nvme2tb      1.81T  4.16G  1.81T        -         -     0%     0%  1.00x    ONLINE  -
seriale2023  14.5T   504K  14.5T        -         -     0%     0%  1.00x    ONLINE  -  ✅ NEW
storage        20T  18.6T  1.43T        -         -     1%    92%  1.00x    ONLINE  -  ✅ UNTOUCHED
```

---

## Next Steps (for Session 33)

### Step 1: Add Bind Mount to Container Config
```bash
# On Proxmox host:
sudo bash -c 'echo "mp2: /seriale2023,mp=/mnt/seriale2023" >> /etc/pve/lxc/102.conf'

# Verify
cat /etc/pve/lxc/102.conf | grep mp
```

### Step 2: Restart Container to Apply Mount
```bash
# On Proxmox host:
sudo pct stop 102
sleep 3
sudo pct start 102

# Verify mount is active (from Proxmox host):
sudo pct exec 102 -- bash -c "ls -la /mnt/seriale2023 && df -h /mnt/seriale2023"
```

### Step 3: Begin Seriale 2023 Transfer
From container (LXC 102):
- Source: 920 NAS (sata3 & sata4, 20TB total, Seriale 2023, ~17TB actual content)
- Target: `/mnt/seriale2023/` (on UGREEN via bind mount)
- Method: NFS mount + rsync (same as Phase 1)
- Estimated duration: 1.8 days at 2.5Gbps (based on Phase 2.5 experience)

---

## Transfer Context (From Previous Sessions)

### Project Overview: 920 NAS Consolidation
- **Phase 1 (COMPLETE):** Filmy920 2018-2021 (8.6TB) → UGREEN ✅
- **Phase 2.5 (IN PROGRESS):** 918 backups (4.07TB) → Homelab 🟡
- **Phase 2 (PENDING):** Filmy920 2022-2025 (3.6TB) → Homelab ⏳
- **Phase 3 (STARTING):** Seriale 2023 (17TB) → UGREEN ⏳ THIS SESSION

### 920 NAS Content (Source)
| Content | Volume | Size | Drives | Status |
|---------|--------|------|--------|--------|
| Filmy920 2018-2021 | volume2 | 8.6TB | sata1+sata2 | ✅ Transferred |
| Filmy920 2022-2025 | volume2 | 3.6TB | sata1+sata2 | ⏳ Pending |
| Seriale 2023 | volume1 | 17TB | sata3+sata4 | ⏳ Starting |

### 920 NAS Drives
| Bay | SATA | Model | Size | Volume | Content | Status |
|-----|------|-------|------|--------|---------|--------|
| 1 | sata1 | ST16000NE000 | 16TB | volume2 | Filmy920 | OK |
| 2 | sata2 | ST16000NE000 | 16TB | volume2 | Filmy920 | ⚠️ Failing (3 UNC errors) |
| 3 | sata3 | ST20000NE000 | 20TB | volume1 | Seriale 2023 | OK |
| 4 | sata4 | ST20000NE000 | 20TB | volume1 | Seriale 2023 | OK |

---

## Key Commands for Reference

**Verify ZFS Pool:**
```bash
sudo zpool list
sudo zpool status seriale2023
```

**Check Container Mount (from container):**
```bash
ls -la /mnt/seriale2023
df -h /mnt/seriale2023
```

**Proxmox API Token:**
```bash
cat ~/.proxmox-api-token
```

**NFS Mount 920 NAS (typical for transfer):**
```bash
sudo mkdir -p /mnt/920-nfs
sudo mount -t nfs 192.168.40.11:/volume1 /mnt/920-nfs
```

---

## Critical Safety Confirmations

✅ **Existing Data Safe:**
- storage pool (20T): UNTOUCHED
- sda+sdb (20TB drives): Unchanged
- Filmy920 2018-2021 on UGREEN: Safe
- 918 backups on homelab: Safe

✅ **New Setup Correct:**
- sdc+sdd (16TB IronWolf Pro): Wiped, pooled, online
- seriale2023 pool: Online, healthy, 14.5T usable
- No data loss, no conflicts

---

## Session Log

**Time:** 26 Dec 2025, ~19:30-20:30 CET

1. Identified drives: sdc, sdd (IronWolf Pro 16TB)
2. Verified data deletion from 918 NAS (checked session files)
3. Confirmed zero data via hexdump
4. Wiped partition tables with sgdisk
5. Created ZFS mirror pool: seriale2023
6. Verified all pools operational
7. Documented for next session

---

**Next Session:** SESSION-33-SERIALE2023-TRANSFER
**Prerequisite:** Restart container and add bind mount (see "Next Steps")
**Expected Duration:** ~1.8 days for transfer + verification

