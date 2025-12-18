# LXC 102 Migration to New NVMe Storage
**Date:** 2025-12-18
**Location:** UGREEN DXP4800+ Proxmox (192.168.40.60)
**Container:** LXC 102 (ugreen-ai-terminal)
**Performed by:** Another Claude Code instance on Proxmox host

---

## Migration Overview

LXC 102 was successfully migrated from the system drive (local-lvm) to a new dedicated 2TB WD_BLACK SN7100 NVMe drive with ZFS storage.

---

## Changes Made

### Storage Location
- **Before:** `local-lvm` (LVM-thin on 119GB system NVMe)
- **After:** `nvme2tb:subvol-102-disk-0` (ZFS on 2TB WD_BLACK SN7100)

### Network Configuration
- **IP Address:** 192.168.40.82 (corrected in documentation)
- **Network:** 192.168.40.x/24

### Storage Configuration
```
rootfs: nvme2tb:subvol-102-disk-0,size=20G
```

---

## Key Benefits

| Feature | Before | After |
|---------|--------|-------|
| Storage Backend | LVM-thin | ZFS |
| Drive | 119GB system NVMe | 2TB WD_BLACK SN7100 |
| Compression | None | LZ4 (~50% space savings) |
| TRIM Support | Manual | Automatic |
| Snapshots | LVM snapshots | ZFS snapshots (faster) |

---

## Verification (Confirmed 2025-12-18)

**Inside Container (LXC 102):**
```bash
$ ip addr show | grep "inet "
    inet 192.168.40.82/24 brd 192.168.40.255 scope global eth0

$ df -h /
Filesystem                  Size  Used Avail Use% Mounted on
nvme2tb/subvol-102-disk-0   20G  826M   20G   5% /

$ mount | grep "/ "
nvme2tb/subvol-102-disk-0 on / type zfs (rw,noatime,xattr,posixacl,casesensitive)
```

**Status:** ✅ Migration successful, container running normally on new storage

---

## Backup Information

**Backup Location (on Proxmox host):**
```
/var/lib/vz/dump/vzdump-lxc-102-2025_12_18-15_31_44.tar.zst
Size: 505MB
```

**Retention:** Keep for 7 days, delete after verifying stability

**Cleanup Command (run on Proxmox host after 1-2 days):**
```bash
# Free 20GB on system drive by removing old LXC disk
sudo lvremove pve/vm-102-disk-0
```

---

## ZFS Features Available

### Create Snapshots (on Proxmox host)
```bash
# Create snapshot before updates
sudo zfs snapshot nvme2tb/subvol-102-disk-0@before-update

# List snapshots
sudo zfs list -t snapshot | grep 102

# Rollback if needed
sudo zfs rollback nvme2tb/subvol-102-disk-0@before-update
```

### Check ZFS Status (on Proxmox host)
```bash
# Pool status
sudo zpool status nvme2tb

# Dataset info
sudo zfs list nvme2tb/subvol-102-disk-0

# Compression stats
sudo zfs get compressratio nvme2tb/subvol-102-disk-0
```

---

## Important Notes

1. **All Proxmox storage commands require `sudo`**
   - `pct`, `qm`, `zfs`, `zpool` commands must be run with sudo

2. **Container access methods:**
   - SSH: `ssh sleszugreen@192.168.40.82`
   - Proxmox console: Web UI at 192.168.40.60:8006
   - Direct entry (emergency): `sudo pct enter 102` from Proxmox host

3. **CLAUDE.md updated:**
   - Corrected IP address: 192.168.40.82
   - Added storage location info
   - Added UGREEN Storage Layout section

4. **Performance improvements:**
   - Faster I/O on dedicated NVMe vs shared system drive
   - LZ4 compression provides ~50% space savings with minimal CPU overhead
   - Auto-TRIM keeps SSD performance optimal

---

## Related Documentation

- Hardware inventory: `~/projects/ai-projects/homelab-hardware/`
- CLAUDE.md: `~/.claude/CLAUDE.md`
- Container specs: See CLAUDE.md → UGREEN Infrastructure section

---

## Rollback Plan (If Needed)

**If migration causes issues:**

1. **Restore from backup (on Proxmox host):**
   ```bash
   # Stop container
   sudo pct stop 102

   # Restore backup
   sudo pct restore 102 /var/lib/vz/dump/vzdump-lxc-102-2025_12_18-15_31_44.tar.zst \
     --storage local-lvm

   # Start container
   sudo pct start 102
   ```

2. **Update IP back to previous if needed**

3. **Verify services are running**

**Note:** Backup is valid for 7 days. After that, the new storage location is permanent.
