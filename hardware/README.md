# Hardware Inventory

**Repository:** Complete hardware documentation for all systems (Desktop, NAS, Infrastructure)
**Owner:** sleszgit
**Created:** 12.12.2025
**Last Updated:** 17.12.2025

---

## Overview

This repository contains comprehensive hardware documentation, analysis, and troubleshooting guides for all systems including desktop computer (DESKTOP24) and NAS devices (918 NAS, second Synology NAS, UGREEN NAS).

---

## Contents

### `/desktop/`
Desktop PC (DESKTOP24) hardware documentation:

- **hardware-info.txt** - Windows systeminfo output (complete specs)
- **DESKTOP24-ANALYSIS.md** - Comprehensive hardware analysis
  - Full component specifications
  - Performance assessments
  - Thermal analysis
  - Upgrade path planning
  - Maintenance schedules
  - Troubleshooting guides
  - Value assessment

### `/nas/`
NAS devices hardware documentation:

- **918-NAS-ANALYSIS.md** - Synology DS918+ inventory and health status
  - Complete disk specifications (4 disks: 2x Seagate, 1x WD, 1x Seagate)
  - Power-on hours: 14k-40k hours
  - Mixed RAID (1x redundant, 2x single)
  - 36TB storage across 3 volumes (33% utilized)
  - Migration planning data

- **920-NAS-ANALYSIS.md** - Synology DS920+ inventory and health status
  - Complete disk specifications (4x Seagate: 2x 20TB, 2x 16TB)
  - Power-on hours: 19k-30k hours
  - Full RAID1 redundancy on both volumes
  - 32TB usable storage (94% utilized - **CRITICAL**)
  - Docker containerization active
  - Urgent migration recommendations

- **UGREEN-NAS-ANALYSIS.md** - UGREEN DXP4800+ NAS inventory and specifications
  - Enterprise-grade Seagate IronWolf Pro 22TB drives (2x units)
  - 44 TB total raw capacity (22 TB with RAID1 redundancy)
  - Intel Pentium Gold 8505 processor (5 cores @ 4.4 GHz)
  - 4GB RAM allocated (Ubuntu 24.04 LXC container)
  - Consolidation target for legacy Synology systems
  - Active data migration from 918 and 920+ NAS

---

## System Specifications Summary

**DESKTOP24** - High-End Gaming/Workstation Desktop

| Component | Specification |
|-----------|---------------|
| **CPU** | Intel Core i7-14700KF (20 cores, 28 threads, up to 5.6 GHz) |
| **Motherboard** | ASRock Z790 Steel Legend WiFi |
| **RAM** | 64GB DDR5-4800 Corsair (2x 32GB) |
| **Cooling** | Corsair H150i ELITE LCD XT (360mm AIO) |
| **GPU** | NVIDIA GeForce RTX 4070 Ti SUPER (16GB) |
| **Storage** | 8TB NVMe SSD (990 EVO Plus 4TB + 2x 980 PRO 2TB) |
| **BIOS** | v21.02 (October 2025) |

**System Rating:** ⭐⭐⭐⭐⭐ (5/5) - Flagship/Enthusiast tier

**Estimated Value:** €2,800-3,800

---

**918 NAS** - Synology DS918+ Network Attached Storage

| Component | Specification |
|-----------|---------------|
| **Model** | Synology DiskStation DS918+ |
| **OS** | DSM 7.2.2 (Build 72806, Nov 10 2025) |
| **CPU** | Intel Celeron J3455 @ 1.50GHz (4 cores) |
| **RAM** | 16GB |
| **Storage Disks** | 4x SATA drives (56TB raw capacity) |
| **Disk Details** | Slot 1: Seagate IronWolf PRO 16TB (14,116 hrs) |
| | Slot 2: Seagate IronWolf PRO 14TB (30,459 hrs) |
| | Slot 3: WD Red Pro 10TB (40,646 hrs) |
| | Slot 4: Seagate 14TB (14,124 hrs) |
| **Total Capacity** | 36TB across 3 volumes (25-44% used) |
| **Network** | 1Gbps Gigabit Ethernet |
| **Health Status** | ✅ All disks healthy - SMART passed |

**Health Assessment:** ⭐⭐⭐⭐ (4/5) - Functional, aging disk in slot 3 (4.6 yrs) candidate for retirement

---

**920 NAS** - Synology DS920+ Network Attached Storage

| Component | Specification |
|-----------|---------------|
| **Model** | Synology DiskStation DS920+ |
| **OS** | DSM 7.2.2 (Build 72806, Jul 21 2025) |
| **CPU** | Intel Celeron J4125 @ 2.00GHz (4 cores) |
| **RAM** | 19GB |
| **Storage Disks** | 4x Seagate IronWolf PRO (2x 20TB + 2x 16TB) |
| **Disk Details** | Slot 1: Seagate IronWolf PRO 20TB (19,047 hrs) |
| | Slot 2: Seagate IronWolf PRO 20TB (19,047 hrs) |
| | Slot 3: Seagate IronWolf PRO 16TB (30,282 hrs) |
| | Slot 4: Seagate IronWolf PRO 16TB (30,282 hrs) |
| **Total Capacity** | 72TB raw / 32TB usable (RAID1) |
| **Current Usage** | 30TB (94% full) - **CRITICAL** |
| **Network** | 1Gbps Gigabit Ethernet |
| **Health Status** | ✅ All disks healthy - Full RAID1 redundancy |
| **Services** | Docker containers (Plex, Git, WebStation, etc.) |

**Health Assessment:** ⭐⭐⭐⭐⭐ (5/5) - Premium hardware, **URGENT: Critical storage capacity (95% full on Volume 1)**

---

**UGREEN NAS** - UGREEN DXP4800+ Consolidated Storage

| Component | Specification |
|-----------|---------------|
| **Model** | UGREEN DXP4800+ |
| **Deployment** | LXC Container 102 (Ubuntu 24.04 LTS) on Proxmox |
| **CPU** | Intel Pentium Gold 8505 @ 4.4GHz (5 cores) |
| **RAM** | 4GB allocated |
| **Storage Drives** | 2x Seagate IronWolf Pro 22TB (ST22000NT001-3LS) |
| **Boot Drive** | Kingston NVMe 120GB (YSO128GTLCW-E3C-2) |
| **Total Capacity** | 44TB raw / 22TB usable (RAID1) |
| **Network** | 1Gbps via Proxmox host (192.168.40.81) |
| **Health Status** | ✅ Fully operational - Enterprise-grade drives |
| **Purpose** | Consolidation target for 918/920+ Synology NAS data migration |

**Health Assessment:** ⭐⭐⭐⭐⭐ (5/5) - Enterprise storage platform, ready for consolidation, **CAPACITY NOTE: Requires RAID5/6 configuration to accommodate incoming 40TB of data**

**Windows Access (Samba/SMB):** ✅ Configured and Working
- **Share:** `\\192.168.40.60\ugreen20tb`
- **Access from:** Windows 192.168.99.6 (separate subnet)
- **Protocol:** SMB3 (Samba 4.22.6)
- **Data Storage:** /storage/Media (ZFS RAID1, 20TB mirrored)
- **Current Content:** 5.7 TB (Movies918, Series918, aaafilmscopy, backupstomove)
- **Proxmox Firewall Rules:** Configured to allow port 445/139 from Windows desktop

---

## Related Repositories

- **Homelab Hardware:** https://github.com/Sleszgit/homelab-hardware
- **UGREEN Infrastructure:** (Coming soon)

---

## Maintenance Status

✅ **DESKTOP24 Analysis:** Complete
✅ **918 NAS Inventory:** Complete (17.12.2025)
✅ **920+ NAS Inventory:** Complete (17.12.2025)
✅ **UGREEN NAS Inventory:** Complete (17.12.2025)
⏳ **Comprehensive Migration Plan:** In progress - UGREEN capacity planning analysis added

---

## Last Updated

**Date:** 17.12.2025
**Updated By:** Claude Code (ugreen-ai-terminal)
**Status:** Active documentation - All NAS systems now fully documented including UGREEN
**Recent Changes:** Added complete UGREEN NAS hardware analysis with capacity planning and migration readiness assessment

---

## License

Personal hardware documentation - All Rights Reserved
