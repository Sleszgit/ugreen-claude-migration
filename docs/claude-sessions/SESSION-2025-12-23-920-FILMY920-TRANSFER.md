# Session: 920 NAS Filmy920 Transfer - Phase 1 Started

**Date:** 2025-12-23
**Status:** Transfer In Progress
**Objective:** Transfer Filmy920 (13TB) from 920 NAS before drive failure

---

## Session Summary

Continued 920 NAS migration planning and **started Filmy920 transfer** to UGREEN. Discovered drive errors on sata2 (16TB) which added urgency to the transfer.

---

## Key Findings This Session

### 920 NAS Drive Layout Confirmed

| Slot | SATA | Drive Model | Size | Volume | Contains |
|------|------|-------------|------|--------|----------|
| Bay 1 | sata1 | ST16000NE000 | 16TB | volume2 | Filmy920 |
| Bay 2 | sata2 | ST16000NE000 | 16TB | volume2 | Filmy920 |
| Bay 3 | sata3 | ST20000NE000 | 20TB | volume1 | Seriale 2023 |
| Bay 4 | sata4 | ST20000NE000 | 20TB | volume1 | Seriale 2023 |

### Drive Error Discovery - sata2 (16TB)

**Kernel logs showed recurring UNC errors:**
```
ata2.00: failed command: READ FPDMA QUEUED
ata2.00: error: { UNC }
```

**SMART data:**
- Reported_Uncorrectables: 3
- ATA Error Count: 4
- Error dates: Dec 15, 16, 18 (recurring)
- Overall health: PASSED (still within threshold)

**Assessment:** Yellow flag - early warning signs of sector degradation. Drive still functional thanks to RAID1 mirror, but should not be reused.

**Warranty:** Valid until December 29, 2026 (~1 year remaining). Seagate RMA possible with SeaTools failure code.

---

## Filmy920 Content Breakdown

| Folder | Size |
|--------|------|
| 2018 | 1.5TB |
| 2019 | 2.3TB |
| 2020 | 3.7TB |
| 2021 | 1.1TB |
| 2022 | 1.4TB |
| 2023 | 712GB |
| 2024 | 540GB |
| 2025 | 466GB |
| TV Shows 2022 | 493GB |
| **Total** | **~13TB** |

---

## Transfer Plan

### Phase 1: To UGREEN (8.6TB) - IN PROGRESS

| Folder | Size | Status |
|--------|------|--------|
| 2018 | 1.5TB | Transferring |
| 2019 | 2.3TB | Queued |
| 2020 | 3.7TB | Queued |
| 2021 | 1.1TB | Queued |

**Method:** NFS mount from 920 → rsync to /storage/Media/Filmy920/
**Estimated time:** ~26-30 hours at 80-95 MB/s
**Expected completion:** Dec 24-25, 2025

### Phase 2: To Homelab (3.6TB) - PENDING

| Folder | Size |
|--------|------|
| 2022 | 1.4TB |
| 2023 | 712GB |
| 2024 | 540GB |
| 2025 | 466GB |
| TV Shows 2022 | 493GB |

**Destination:** Homelab /WD10TB/ pool (8.5TB free)

---

## Commands Used

### NFS Mount on UGREEN
```bash
sudo mkdir -p /mnt/920-filmy920
sudo mount -t nfs -o ro,vers=4,soft,timeo=30 192.168.40.20:/volume2/Filmy920 /mnt/920-filmy920
sudo mkdir -p /storage/Media/Filmy920
sudo chown -R sleszugreen:sleszugreen /storage/Media/Filmy920/
```

### Transfer Command (in screen session)
```bash
screen -S filmy920-transfer

sudo rsync -avh --progress --partial "/mnt/920-filmy920/Filmy920/2018" /storage/Media/Filmy920/ && \
sudo rsync -avh --progress --partial "/mnt/920-filmy920/Filmy920/2019" /storage/Media/Filmy920/ && \
sudo rsync -avh --progress --partial "/mnt/920-filmy920/Filmy920/2020" /storage/Media/Filmy920/ && \
sudo rsync -avh --progress --partial "/mnt/920-filmy920/Filmy920/2021" /storage/Media/Filmy920/ && \
echo "=== ALL TRANSFERS COMPLETE ===" && date
```

### Monitor Progress
```bash
screen -r filmy920-transfer
# Detach: Ctrl+A then D
```

---

## Storage Capacity Summary

| Device | Total Usable | Used | Free |
|--------|--------------|------|------|
| UGREEN (22TB mirror) | ~20TB | 10.2TB | 9.7TB |
| Homelab WD10TB pool | ~9TB | 529GB | 8.5TB |

After Phase 1: UGREEN will have ~1.1TB free
After Phase 2: Homelab will have ~4.9TB free

---

## Next Steps

1. [ ] Wait for Phase 1 transfer to complete (~26-30 hours)
2. [ ] Mount 920 NFS on Homelab
3. [ ] Transfer remaining 3.6TB to Homelab
4. [ ] Verify all data integrity
5. [ ] Run SeaTools on sata2 to generate failure code for RMA
6. [ ] File Seagate warranty claim for failing 16TB drive
7. [ ] Plan Seriale 2023 (17TB) transfer

---

## Related Documentation

- Previous session: `SESSION-2025-12-23-920-TRANSFER-PLANNING.md`
- 920 NAS analysis: `/home/sleszugreen/hardware/nas/920-NAS-ANALYSIS.md`
- Transfer project: `/home/sleszugreen/projects/nas-transfer/`

---

**Session Status:** Transfer in progress
**Last Updated:** 2025-12-23 ~18:30 CET
