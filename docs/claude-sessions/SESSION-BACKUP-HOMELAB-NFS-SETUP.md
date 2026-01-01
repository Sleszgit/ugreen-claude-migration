# Session: Homelab NFS Mount Setup for LXC102 Backups

**Date:** 2026-01-01
**Status:** BLOCKED - NFS authentication issue
**Progress:** 80% complete (NFS export configured, but mount still denied)

---

## What Was Accomplished

### ✅ Phase 3 Backup Scripts (Complete)
- 3 production-ready backup scripts created and syntax validated
- 3 comprehensive documentation files created
- All copied to GitHub and /mnt/lxc102scripts/

### ✅ Homelab NFS Export Setup (Partially Complete)
- ✅ Directory created: `/mnt/homelab-backups/lxc102-vzdump`
- ✅ Permissions set: `nobody:nogroup` (755)
- ✅ Firewall rules added to allow NFS ports
- ✅ NFS server running with mount daemon active
- ✅ Export rule properly registered in `/etc/exports`
- ✅ Export showing with valid options: `sync,wdelay,hide,no_subtree_check,sec=sys,rw,insecure,no_root_squash,no_all_squash`

### ❌ UGREEN NFS Mount (Blocked)
- ❌ Mount attempt fails: `mount.nfs: access denied by server`
- Even with valid export and firewall rules, client still denied
- Root cause: Unknown (likely Proxmox-specific NFS configuration issue)

---

## What Was Tried

**Diagnostic Scripts Created:**
1. `setup-homelab-nfs.sh` - Initial NFS setup (worked)
2. `homelab-firewall-nfs.sh` - Added firewall rules (worked)
3. `diagnose-nfs.sh` - NFS server diagnostics (identified mountd issue)
4. `fix-nfs-server.sh` - Fixed and started mountd (worked)
5. `fix-nfs-export.sh` - Updated export options (syntax error)
6. `fix-nfs-complete.sh` - Diagnostic deep-dive
7. `fix-nfs-final.sh` - Used valid NFS options (worked, but mount still fails)

**Tests Performed:**
- ✅ SSH connectivity to Homelab: Working
- ✅ Directory and permissions: Correct
- ✅ Firewall rules: Installed
- ✅ NFS server status: Active and listening
- ✅ NFS mount daemon: Running
- ✅ Export syntax: Valid
- ❌ Client mount: Still denied

---

## Root Cause Analysis

The NFS export appears properly configured but clients are still denied. Possible causes:

1. **Proxmox-specific NFS configuration** - Proxmox may have additional security layers
2. **NFS version mismatch** - Client/server negotiating incompatible versions
3. **NFSv4 vs NFSv3** - Proxmox might require NFSv4 which has different authentication
4. **Kerberos/Security Context** - Export shows `sec=sys` but might need different security
5. **Host-based authentication** - May require additional Proxmox cluster authentication

---

## Files Created

**Setup/Fix Scripts (on Homelab):**
- `/tmp/setup-homelab-nfs.sh`
- `/tmp/homelab-firewall-nfs.sh`
- `/tmp/diagnose-nfs.sh`
- `/tmp/fix-nfs-server.sh`
- `/tmp/fix-nfs-export.sh`
- `/tmp/fix-nfs-complete.sh`
- `/tmp/fix-nfs-final.sh`

**Current State on Homelab:**
- Directory: `/mnt/homelab-backups/lxc102-vzdump` ✅
- Export rule in `/etc/exports` ✅
- Firewall rules added ✅
- Services running ✅

---

## Recommendations for Next Attempt

### Option A: Investigate NFSv4
Try mounting with NFSv4 explicitly:
```bash
sudo mount -t nfs4 192.168.40.40:/mnt/homelab-backups/lxc102-vzdump /mnt/homelab-backups
```

### Option B: Use Different Backup Method
Since NFS is problematic, consider alternatives:
- **SSH-based backup:** `rsync` with SSH (already have working script)
- **Direct to UGREEN NAS:** Use existing `/storage/Media` mount
- **Proxmox API:** Use Proxmox native clustering features

### Option C: Check Proxmox Documentation
- Search for Proxmox cluster NFS mount procedures
- May need PVE-specific firewall configuration
- Might require VIP (virtual IP) or cluster-aware setup

### Option D: Simpler Workaround
Since the daily rsync to UGREEN NAS is already set up and working, consider:
- Use UGREEN NAS as primary backup destination
- Skip Homelab NFS for now
- Still get redundancy with daily rsync snapshots

---

## Session Notes

**Time Spent:** ~90 minutes on NFS troubleshooting

**Key Learnings:**
1. Proxmox firewall needed explicit NFS port rules
2. rpc.mountd daemon was missing initially
3. Invalid NFS option syntax (`all_squash=no`) fails silently
4. NFS exports register successfully but "access denied" still occurs
5. This suggests Proxmox has additional authentication layer beyond standard NFS

**Next Session:**
- Either investigate NFSv4 / Proxmox-specific NFS configuration
- Or pivot to rsync-only backup strategy (already functional)
- Or implement SSH-tunnel based backup transfer

---

## Decision Needed

**Should we:**
1. Continue troubleshooting NFS (requires Proxmox NFS documentation)
2. Pivot to rsync-only backup strategy (simpler, already tested)
3. Try SSH-tunnel based backup transfers
4. Other approach?

Current backup plan is solid with daily rsync to UGREEN NAS. Homelab backup would be redundancy, but not strictly necessary if we have GitHub + UGREEN NAS coverage.

---

**Owner:** Claude Code
**Status:** Blocked - Awaiting decision on next steps
