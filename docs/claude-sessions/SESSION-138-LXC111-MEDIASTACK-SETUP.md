# Session 138: LXC111 MediaStack Container Setup

**Date:** 2026-01-18
**Time:** 05:37 UTC
**Status:** In Progress - Ready for deployment

---

## Objectives Completed

✅ **Template Verification**
- Confirmed Debian 12.12-1 template exists on UGREEN host
- Created script with dynamic template discovery (wildcard matching)

✅ **Script Creation & Testing**
- Created `/mnt/lxc102scripts/create-lxc111-mediastack.sh` (bind mount for accessibility)
- Copied to `/home/sleszugreen/scripts/lxc111/create-lxc111-mediastack.sh` (local reference)
- Consulted Gemini for bash script audit and Proxmox syntax validation

✅ **Critical Fixes Applied (User-Directed)**
1. **Networking:** Removed VLAN10 tags, switched to standard vmbr0 bridge with DHCP
2. **Template Selection:** Dynamic discovery using `debian-12-standard_*_amd64.tar.zst` pattern
3. **ID Mapping:** Fixed subordinate GID delegation issue by:
   - Auto-detecting `users` group (GID 100) and `render` group (GID 993)
   - Adding missing delegations to `/etc/subgid` before container creation
   - Preserving complex ID mapping logic that now works with proper permissions

✅ **Bind Mounts Configured**
- `/SeriesUgreen` → `/mnt/media/tv_ugreen`
- `/storage/Media/Series918/TVshows918` → `/mnt/media/tv_918`
- `/nvme2tb/lxc102scripts` → `/mnt/lxc102scripts` (for cross-machine script access)

✅ **GPU Passthrough Configured**
- Intel QuickSync via `/dev/dri/renderD128` (device 226:128)
- Dynamic render group GID mapping

---

## Key Decisions & Rationale

**Network Mode: DHCP**
- User chose standard 192.168.40.x network (not VLAN 10)
- Script supports easy switch to static IP by editing `NETWORK_MODE` variable

**ID Mapping Solution**
- User rejected `idmap=both` (not valid Proxmox syntax)
- Correct approach: Pre-authorize GIDs in `/etc/subgid` before container creation
- Script now auto-fixes permissions before `pct create` runs

**Template Discovery**
- Avoided hardcoding version string
- Script finds latest Debian 12 template automatically
- Prevents version mismatch errors

---

## Script Features

**Validation Section:**
- Checks `pct` command availability
- Verifies LXC ID not already in use
- Confirms storage pool exists
- Validates bind mount paths
- Auto-detects and authorizes render/users groups

**Dynamic Delegations:**
- Reads actual GID values from `getent group`
- Checks existing `/etc/subgid` entries
- Adds missing delegations without duplicates
- Logs all permission grants

**Network Configuration:**
- Flexible: DHCP or static IP
- Commented examples for static configuration
- Properly quoted shell variables

**Verification Steps:**
- Confirms container boots
- Validates network assignment
- Tests bind mounts accessibility
- Checks network connectivity (ping 8.8.8.8)

---

## Files Created/Modified

| File | Location | Status |
|------|----------|--------|
| `create-lxc111-mediastack.sh` | `/mnt/lxc102scripts/` | ✅ Final (bind mount) |
| `create-lxc111-mediastack.sh` | `/home/sleszugreen/scripts/lxc111/` | ✅ Final (local copy) |

---

## Next Steps (Pending Execution)

1. **Destroy existing LXC 111** (from failed attempt):
   ```bash
   sudo pct destroy 111
   ```

2. **Execute script on UGREEN HOST:**
   ```bash
   sudo bash /nvme2tb/lxc102scripts/create-lxc111-mediastack.sh
   ```

3. **After container is online:**
   - Set up SSH access from LXC102 to LXC111
   - Verify all mounts are accessible
   - Test GPU passthrough capability

---

## Deployment Configuration

**Container Specs:**
- VMID: 111
- Hostname: MediaStack
- Cores: 4
- Memory: 8192 MB
- Swap: 1024 MB
- Storage: 32 GB (local-lvm)
- Unprivileged: Yes

**Network:**
- Bridge: vmbr0 (standard Ugreen network)
- IP: DHCP (auto-assigned in 192.168.40.x range)

**Groups Authorized:**
- users (GID 100) - for media data access
- render (GID 993) - for GPU passthrough

---

## Technical Notes

**Bash Script Standards Applied:**
- ✅ `set -Eeuo pipefail` header
- ✅ ERR trap for error handling
- ✅ Explicit `log()` function (no `set -x`)
- ✅ Upfront validation before state changes
- ✅ All variables properly quoted
- ✅ No global output redirection

**Proxmox Syntax:**
- Corrected: `bridge=vmbr0,tag=10` → `bridge=vmbr0` (tag removed)
- Corrected: Hardcoded template → Dynamic discovery
- Corrected: ID mapping → Subordinate GID pre-authorization

**User Environment Details:**
- Host render group GID: 993
- Host users group GID: 100
- Available Debian 12 template: debian-12-standard_12.12-1_amd64.tar.zst

---

## Session Context

**Device:** UGREEN DXC4800+ Proxmox (192.168.40.60)
**Working Location:** LXC 102 (ugreen-ai-terminal)
**Target:** New LXC 111 (MediaStack) on same host

---

**Last Updated:** 2026-01-18 05:37 UTC
**Ready for:** Container destruction & deployment script execution

