# Phase 1a ZFS Error Investigation

**Date:** 6 January 2026
**Error:** `unable to parse zfs volume name '100G'`
**Status:** BLOCKED - Awaiting Gemini consultation

---

## Issue Description

Phase 1a script fails when trying to create VM100 disk on ZFS pool.

**Error Output:**
```
[2026-01-06 10:10:14] [INFO] [2/4] Creating VM100...
[2026-01-06 10:10:14] [INFO] Creating VM100 (ugreen-infra)...
unable to parse zfs volume name '100G'
[2026-01-06 10:10:14] [ERROR] Script failed at line 115 with exit code 255
```

---

## Storage Configuration

```
Storage Type: zfspool
Storage Pool: nvme2tb
Mount Point: /nvme2tb
Content: rootdir, images
```

---

## Script Troubleshooting Attempts

### Attempt 1: Initial Run
**Command:**
```bash
--scsi0 "${STORAGE_POOL}:${VM_DISK_SIZE},format=raw"
```
**Error:** `unable to parse zfs volume name '100G'`
**Analysis:** `format=raw` not compatible with ZFS

### Attempt 2: Removed format=raw
**Changed to:**
```bash
--scsi0 "${STORAGE_POOL}:${VM_DISK_SIZE}"
```
(where STORAGE_POOL=nvme2tb, VM_DISK_SIZE=100G)

**Result:** Same error: `unable to parse zfs volume name '100G'`
**Analysis:** The issue persists even without format parameter

---

## Current Script State

**File:** `/mnt/lxc102scripts/ugreen-phase1-vm100-create.sh`

**Current problematic lines (107-108):**
```bash
--efidisk0 "${STORAGE_POOL}:256" \
--scsi0 "${STORAGE_POOL}:${VM_DISK_SIZE}" \
```

**Where:**
- STORAGE_POOL = "nvme2tb"
- VM_DISK_SIZE = "100G"
- VLAN_TAG = "10"

---

## Questions for Gemini

1. What is the correct syntax for creating VM disks on ZFS pools in Proxmox?
2. Should the disk size be specified differently (e.g., "100" without "G")?
3. Is there a ZFS-specific format parameter needed?
4. Should we use a different storage pool reference?
5. Are there working examples of qm create on ZFS in Proxmox documentation?

---

## Relevant Context

- Proxmox Host: UGREEN (192.168.40.60)
- Proxmox Version: (can check with `pveversion`)
- VM being created: VM100 (ugreen-infra)
- Target network: VLAN10 (10.10.10.100/24)
- Disk size needed: 100GB

---

## HOLD Status

⏸️ **Script modifications PAUSED**
- Do not modify Phase 1a script further
- Awaiting Gemini consultation on correct ZFS syntax
- Will resume after clarification

---

**Session:** 97 continued
**Created:** 6 January 2026 10:10 CET
