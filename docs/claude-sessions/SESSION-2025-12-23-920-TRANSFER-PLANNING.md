# Session: 920 NAS Transfer Planning & Infrastructure Consolidation

**Date:** 2025-12-23
**Status:** Planning Phase - Awaiting User Input
**Objective:** Plan 920 NAS decommissioning and infrastructure consolidation

---

## Session Summary

Discussed the strategy for:
1. Transferring 30TB data from 920 NAS to UGREEN
2. Consolidating infrastructure to 2 devices (UGREEN + Homelab)
3. Setting up Claude Code management architecture
4. Reusing drives from decommissioned 918 and 920 NAS units

---

## Hardware Corrections Made

During this session, corrected hardware specifications for UGREEN DXP4800+:

| Spec | Previously Listed | **Actual** |
|------|-------------------|------------|
| **CPU** | Intel N100 (4 cores) | **Intel Pentium Gold 8505** (5C/6T @ 4.4GHz) |
| **RAM** | 8GB | **64GB DDR5** |

---

## Infrastructure Overview

### Current State (3 devices)

| Device | IP | CPU | RAM | Storage Bays | Status |
|--------|-----|-----|-----|--------------|--------|
| **UGREEN DXP4800+** | 192.168.40.60 | Pentium Gold 8505 | 64GB DDR5 | 4 (2 used, 2 empty) | Active - Primary |
| **Homelab** | 192.168.40.40 | i5-13500 (14C/20T) | 96GB DDR5 | 8 (2 used, 6 empty) | Active |
| **920 NAS** | 192.168.40.20 | J4125 | 19GB | 4 (all used) | To Decommission |

### Target State (2 devices)

| Device | Role | Storage |
|--------|------|---------|
| **UGREEN** | Primary Claude Code Hub + NAS | 74TB raw (after 918 drives added) |
| **Homelab** | Compute Powerhouse + Secondary Storage | 72TB+ raw (920 drives + existing) |

---

## Drive Inventory

### 918 NAS (Already Decommissioned - Drives Available)

| Slot | Model | Capacity | Age | Reuse Status |
|------|-------|----------|-----|--------------|
| 1 | Seagate IronWolf PRO | 16TB | 1.6 yrs | **Reuse** → UGREEN Bay 3 |
| 2 | Seagate IronWolf PRO | 14TB | 3.5 yrs | **Reuse** (monitor) → TBD |
| 3 | WD Red Pro | 10TB | 4.6 yrs | **RETIRE** |
| 4 | Seagate | 14TB | 1.6 yrs | **Reuse** → UGREEN Bay 4 |

### 920 NAS (To Decommission - 30TB Data)

| Slot | Model | Capacity | Age | Destination |
|------|-------|----------|-----|-------------|
| 1 | Seagate IronWolf PRO | 20TB | 2.2 yrs | Homelab |
| 2 | Seagate IronWolf PRO | 20TB | 2.2 yrs | Homelab |
| 3 | Seagate IronWolf PRO | 16TB | 3.5 yrs | Homelab |
| 4 | Seagate IronWolf PRO | 16TB | 3.5 yrs | Homelab |

### UGREEN DXP4800+ (Current)

| Bay | Current | After Phase 1 |
|-----|---------|---------------|
| 1 | Seagate IronWolf Pro 22TB | Same |
| 2 | Seagate IronWolf Pro 22TB | Same |
| 3 | EMPTY | 918's 16TB drive |
| 4 | EMPTY | 918's 14TB drive |

### Homelab (192.168.40.40)

| Bay | Current | After Phase 3 |
|-----|---------|---------------|
| 1 | Unknown | Same |
| 2 | Unknown | Same |
| 3-6 | EMPTY | 920's 4 drives |
| 7-8 | EMPTY | Available |

---

## Proposed Migration Plan

### Phase 1: Expand UGREEN Capacity
- Add 918's 16TB drive to UGREEN Bay 3
- Add 918's 14TB drive to UGREEN Bay 4
- Result: 74TB raw capacity on UGREEN

### Phase 2: Transfer 920 → UGREEN
- Use NFS mount method (same as successful 918 transfer)
- Transfer 30TB (17TB Seriale + 13TB Filmy)
- Verify all data integrity

### Phase 3: Move 920 Drives to Homelab
- Physically move 4 drives (2x20TB + 2x16TB) to Homelab
- Configure ZFS array on Homelab
- Result: 72TB raw capacity added to Homelab

### Phase 4: Finalize Configuration
- Set up SSH from UGREEN to Homelab
- Configure Claude Code management architecture
- Update documentation

---

## Claude Code Architecture Decision

**Recommendation: UGREEN as Primary Claude Code Hub**

```
┌─────────────────────────────────────────────────────────────────┐
│                     WINDOWS DESKTOP                             │
│                    (MobaXterm / SSH)                            │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              UGREEN DXP4800+ (192.168.40.60)                    │
│                    PRIMARY CLAUDE CODE HUB                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ LXC 102 (ugreen-ai-terminal)                            │   │
│  │ • Claude Code PRIMARY instance                          │   │
│  │ • Infrastructure management scripts                     │   │
│  │ • Documentation & session history                       │   │
│  │ • SSH keys to all other devices                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│  • Portainer (Docker management)                               │
│  • Media storage (74TB after expansion)                        │
│  • NFS/SMB shares                                              │
└─────────────────────────────┬───────────────────────────────────┘
                              │ SSH
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              HOMELAB (192.168.40.40)                            │
│                    COMPUTE POWERHOUSE                           │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ LXC 102 (homelab-ai-terminal)                           │   │
│  │ • Claude Code SECONDARY instance                        │   │
│  │ • Local operations when needed                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│  • VMs for development/testing                                 │
│  • Heavy containers                                            │
│  • Archive storage (72TB+ after 920 drives)                    │
└─────────────────────────────────────────────────────────────────┘
```

**Rationale:**
- UGREEN has 64GB RAM - plenty for management tasks
- Already configured with auto-update, documentation
- Always-on NAS with low power consumption (~15W)
- 2.5GbE networking for fast transfers
- Can SSH to Homelab for heavy compute tasks

---

## Pending Information

Before proceeding, need to know:

1. **Homelab's current drives** (bays 1-2)
   - Run on homelab: `lsblk -o NAME,SIZE,MODEL`

2. **Destination for 918's third reusable drive** (14TB, slot 2)
   - Homelab? Keep as spare?

3. **User approval** of overall plan direction

---

## Related Documentation

- `/home/sleszugreen/hardware/nas/918-NAS-ANALYSIS.md` - 918 drive specs
- `/home/sleszugreen/hardware/nas/920-NAS-ANALYSIS.md` - 920 drive specs
- `/home/sleszugreen/hardware/nas/UGREEN-NAS-ANALYSIS.md` - UGREEN specs
- `/home/sleszugreen/projects/nas-transfer/SESSION-STATUS.md` - 918 transfer history

---

## Next Steps

1. User to provide Homelab drive information
2. User to confirm plan direction
3. Begin Phase 1: Add 918 drives to UGREEN
4. Configure ZFS array on expanded UGREEN
5. Begin 920 NFS transfer

---

**Session Status:** Paused - Awaiting User Input
**Last Updated:** 2025-12-23
