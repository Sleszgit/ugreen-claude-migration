# Session 128: SMB Share Access Fixed - Root Cause Analysis

**Date:** 15 January 2026
**Status:** ✅ Complete - SMB shares fully accessible
**Context:** Homelab Proxmox (192.168.40.40) SMB shares → Windows Client (192.168.99.x)

---

## 🎯 Problem Statement

Windows Client unable to map SMB shares (`FilmsHomelab`, `SeriesHomelab`) from Homelab despite:
- Samba configuration correct and validated
- Services running (smbd/nmbd)
- Port 445 listening on all interfaces
- Network connectivity working (ping, SSH successful)

**Error Symptoms:**
- Windows Error 85: "Local device name is already in use"
- Windows Error 1202: "The local device name has a remembered connection"
- Windows Error 67: "The network name cannot be found"
- `Test-NetConnection` on port 445 failed despite successful ping

---

## 🔍 Root Causes Identified

### 1. Windows Registry "Ghost" Drives
**Issue:** Windows Explorer retained stale registry keys for drive letters M, N, I, and J even after `net use /delete` commands.

**Impact:** Blocked reuse of drive letters despite previous connections being removed. Kernel-level handles persisted.

**Evidence:** Registry keys remained in `HKCU\Network\...` after deletion attempts.

---

### 2. Linux Filesystem Permissions (Critical)
**Issue:** Parent mount point `/Seagate-20TB-mirror/` lacked **execute (+x) permission for "others"**.

**Impact:** Samba could not traverse from `/Seagate-20TB-mirror/` to subdirectories like `FilmsHomelab` and `SeriesHomelab`. Permission error occurred despite directory being browseable in config.

**Key Insight:** Samba needs `+x` on parent directories to navigate the path, even if the target directory has correct permissions.

---

### 3. Proxmox Host Firewall (The Final Blocker)
**Issue:** Default Proxmox firewall (iptables) was **dropping incoming TCP traffic on port 445** from external VLANs.

**Impact:** Despite Samba listening on `0.0.0.0:445`, firewall rules blocked connections from Windows Client (192.168.99.x) on VLAN 99.

**Root Cause Pattern:** This matches the "Firewall Change Safety Protocol" scenario - cross-VLAN traffic (VLAN99 → VLAN40) being blocked by `DEFAULT_FORWARD_POLICY="DROP"` or specific input rules.

---

## ✅ Applied Solutions

### 1. Client-Side (Windows 11)

**Registry Cleanup:**
```batch
reg delete HKCU\Network\I /f
reg delete HKCU\Network\J /f
```

**Session Reset:** Restarted Windows to clear kernel-level handles on ghost drive letters.

**Outcome:** Drive letters I and J now available for remapping.

---

### 2. Server-Side (Proxmox/Debian)

**Permission Fix - Parent Directory Traversal:**
```bash
sudo chmod a+x /Seagate-20TB-mirror
```

**Why this works:** Samba requires execute permission on all directories in the path (including parent), not just the target directory. This allows SMB to traverse `/Seagate-20TB-mirror/` → `FilmsHomelab`.

---

### 3. Firewall Exception - THE CRITICAL FIX

**Root Issue:** Proxmox iptables was blocking incoming TCP on port 445.

**Solution - Allow SMB Traffic:**
```bash
sudo iptables -I INPUT -p tcp --dport 445 -j ACCEPT
```

**Persistence - Survive Reboots:**
```bash
sudo apt-get install iptables-persistent
sudo netfilter-persistent save
```

**Outcome:** Port 445 now open and verified via `Test-NetConnection`.

---

## 📊 Current Status

| Component | Status |
|-----------|--------|
| Port 445 Connectivity | ✅ Open (verified) |
| FilmsHomelab Share | ✅ Mapped to Drive I |
| SeriesHomelab Share | ✅ Mapped to Drive J |
| Authentication | ✅ Using `samba-homelab` user |
| Registry State | ✅ Clean (ghost drives removed) |
| Filesystem Permissions | ✅ Parent directory traversable |
| Firewall Rules | ✅ Persistent (iptables-persistent) |

---

## 🎓 Key Learnings

### 1. Multi-Layer Problem
This was not a single point of failure but a **combination of three independent issues**:
- Client: Ghost registry entries
- Server-FS: Permission bits on parent directory
- Server-FW: Firewall blocking the port

All three had to be fixed for access to work.

### 2. SMB Path Traversal Requirements
**Important:** Samba (and CIFS in general) requires **execute (+x) permission on all directories in the path**, not just the target. This is a common gotcha - target directory can have 755, but if parent has 750, access fails.

```
Example:
/Seagate-20TB-mirror/     ← MUST have +x (was missing)
└── FilmsHomelab/         ← Must have +x (had 755)
```

### 3. Firewall Change Safety Protocol In Action
This incident exemplified the exact scenario documented in CLAUDE.md:
- ✅ Ping works (routing OK)
- ❌ TCP port 445 fails (firewall blocking)
- ✅ Other services on same host accessible (different ports)

Cross-VLAN SMB access requires explicit firewall rules on the receiving host (Homelab), not just on the border firewall.

### 4. Windows Registry Persistence
Windows kernel-level handles persist across `net use /delete` commands. Registry entries must be manually deleted, and a session restart is required to clear kernel state.

---

## 🔗 Related Infrastructure Notes

**Network Topology:**
- Windows Client: 192.168.99.x (Desktop/Management VLAN 99)
- Homelab: 192.168.40.40 (Storage VLAN 40)
- Cross-VLAN requires both:
  - Linux firewall rules to accept the traffic
  - Proper filesystem permissions on the server

**Firewall Command Chain:**
```bash
# What you applied:
sudo iptables -I INPUT -p tcp --dport 445 -j ACCEPT
sudo apt-get install iptables-persistent
sudo netfilter-persistent save

# This can be verified with:
sudo iptables -L INPUT -v | grep 445
```

---

## 📂 Files Modified

**On Homelab (192.168.40.40):**
1. `/Seagate-20TB-mirror/` - Permissions changed from `dr-xr-xr-x` to `dr-xr-xr-x` (added execute for others)
2. Firewall rules saved via iptables-persistent

**On Windows Client:**
1. Registry keys deleted: `HKCU\Network\I` and `HKCU\Network\J`

---

## 🚀 Next Steps

**Option 1: Make Firewall Change Permanent in Proxmox Config**
Currently using iptables-persistent. Consider adding to `/etc/pve/firewall/node.fw` for centralized management.

**Option 2: Monitor Firewall Rules**
Verify persistence across reboots when next maintenance window occurs.

**Option 3: Document in Infrastructure**
Update `INFRASTRUCTURE.md` with this cross-VLAN SMB access pattern for future reference.

---

## 🎯 Session Summary

| Item | Status |
|------|--------|
| FilmsHomelab Share Access | ✅ Working |
| SeriesHomelab Share Access | ✅ Working |
| Windows Mapping Persistence | ✅ Tested |
| Firewall Rules Persistent | ✅ Configured |
| Root Cause Identified | ✅ Yes (3-layer issue) |
| Documentation Complete | ✅ Yes |

**Session Status:** Complete - SMB shares fully functional and documented

---

**Generated:** 15 January 2026
**Location:** LXC 102 (UGREEN)
**Related Sessions:** 126 (initial assessment), 127 (script execution & diagnostics)
**Next Review:** After next Homelab reboot to confirm firewall persistence
