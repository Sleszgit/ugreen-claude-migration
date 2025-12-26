# Session 29: Proxmox API ACL Fix (26 Dec 2025)

## Objective
Fix read-only API token permissions for container → Proxmox host access. The `claude-reader@pam!claude-token` had limited permissions causing `/nodes/ugreen/status` and other endpoints to fail with "Permission check failed" errors.

## Problem Analysis

**Initial Status:**
- ✅ Basic API queries working (`/nodes`, `/nodes/ugreen/qemu`, `/nodes/ugreen/lxc`)
- ❌ `/nodes/ugreen/status` - "Permission check failed (/nodes/ugreen, Sys.Audit)"
- ❌ `/storage` - Empty array
- ❌ `/cluster/status` - Permission denied

**Root Cause:**
ACL (Access Control List) rules from previous session were never applied. Query showed empty ACL configuration.

## Solution Implemented

### Created 3 Scripts in `/mnt/lxc102scripts/`

#### 1. **fix-proxmox-acl-claude.sh** (6.7 KB)
Applies correct ACL permissions on Proxmox host:
- Pre-flight checks (sudo, pveum, user/token exist)
- Applies PVEAuditor role on 7 critical paths:
  - `/`, `/nodes`, `/nodes/ugreen`, `/storage`, `/vms`, `/qemu`, `/lxc`
- Verifies ACL rules applied
- Tests API endpoints
- Provides troubleshooting guidance

**Execution:** `sudo bash /nvme2tb/lxc102scripts/fix-proxmox-acl-claude.sh`

**Result:** ✅ All ACL rules successfully applied

#### 2. **test-proxmox-api.sh** (6.3 KB)
Tests API access from container:
- Checks token file existence
- Tests network connectivity to Proxmox
- Queries 6 key endpoints
- Provides detailed failure diagnostics

**Execution:** `bash /mnt/lxc102scripts/test-proxmox-api.sh`

**Note:** Requires `grep` and `sed` (may not be installed in container)

#### 3. **test-api-simple.sh** (New)
Simplified test without grep/sed dependency - returns raw API responses

#### 4. **fix-firewall-syntax.sh** (New)
Removes problematic firewall config lines:
- Removes lines 27-28 with conntrack syntax errors
- Backs up original config
- Validates new syntax
- Restarts firewall
- Auto-rollback on failure

**Execution:** `sudo bash /nvme2tb/lxc102scripts/fix-firewall-syntax.sh`

### Comprehensive Documentation

#### **PROXMOX-ACL-FIX-README.md**
Complete guide including:
- Problem summary
- Step-by-step fix procedure
- Troubleshooting reference
- File locations
- Quick reference commands
- Rollback instructions

## Issues Discovered During Execution

### Issue 1: Firewall Config Parsing Errors
```
/etc/pve/firewall/cluster.fw (line 5): can't parse option
/etc/pve/firewall/cluster.fw (line 27): unable to parse
/etc/pve/firewall/cluster.fw (line 28): unable to parse
```

**Cause:** Lines 27-28 contained invalid conntrack syntax:
```bash
IN ACCEPT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog
IN ACCEPT -p udp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog
```

**Solution:** Created `fix-firewall-syntax.sh` to remove these lines and validate syntax

## Files Created/Modified

### New Files (In Bind Mount)
```
/mnt/lxc102scripts/
├── fix-proxmox-acl-claude.sh           (6.7 KB) - ACL fix script
├── test-proxmox-api.sh                 (6.3 KB) - Comprehensive API test
├── test-api-simple.sh                  (New)    - Simple API test
├── fix-firewall-syntax.sh               (New)    - Firewall config fix
└── PROXMOX-ACL-FIX-README.md           (Complete guide)
```

All accessible as:
- Container: `/mnt/lxc102scripts/`
- Proxmox host: `/nvme2tb/lxc102scripts/`

## Current Status

### ACL Setup
✅ **Applied:** PVEAuditor role for claude-reader@pam on:
- `/` (cluster-wide)
- `/nodes` (all nodes)
- `/nodes/ugreen` (specific node)
- `/storage` (storage pools)
- `/vms`, `/qemu`, `/lxc` (resource types)

### Firewall Config
⚠️ **Issue:** Syntax errors in `/etc/pve/firewall/cluster.fw` preventing proper rule application

**Fix:** Run `sudo bash /nvme2tb/lxc102scripts/fix-firewall-syntax.sh` on Proxmox host

### Expected Next Steps
1. Run firewall syntax fix script on Proxmox host
2. Test API from container: `bash /mnt/lxc102scripts/test-api-simple.sh`
3. Verify `/nodes/ugreen/status` returns online status (no permission error)

## Token Usage
- Session tokens used: ~165,000 / 200,000
- Remaining: ~35,000

## References
- Proxmox API: https://pve.proxmox.com/wiki/Proxmox_VE_API
- pveum manual: https://pve.proxmox.com/pve-docs/pveum.1.html
- User Management: https://pve.proxmox.com/wiki/User_Management

## Notes
- All scripts are idempotent (safe to run multiple times)
- Backups created before any modifications
- Rollback instructions provided in each script
- ACL fix successfully applied; firewall config needs syntax correction
