# VLAN10 Configuration Fix Summary

**Date:** 2026-01-04
**Status:** Corrected & Documented
**Files:**
- `/mnt/lxc102scripts/network-interfaces.vlan10.CORRECTED.new` (Proxmox deploy)
- `/home/sleszugreen/docs/network-interfaces.vlan10.CORRECTED.new` (Reference)

---

## Why Previous Configuration Failed

The original `network-interfaces.vlan10.new` file had a **fundamental architectural error** that caused automatic rollback:

### ❌ BROKEN Configuration (Previous)

```
auto vmbr0
iface vmbr0 inet static
    address 192.168.40.60/24        ← WRONG: Bridge can't have IP when VLAN-aware
    gateway 192.168.40.1
    bridge-vlan-aware yes
    bridge-pvid 40
    bridge-vids 10 40
```

**Problem:** When `bridge-vlan-aware yes` is enabled, untagged traffic (like SSH) goes to VLAN 40 (the PVID). The bridge itself becomes a VLAN-aware switch, NOT a regular network interface. You cannot assign an IP directly to it.

### ✅ CORRECTED Configuration (New)

```
auto vmbr0
iface vmbr0 inet manual             ← CORRECT: Bridge in manual mode
    bridge-ports nic1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-pvid 40                  ← Untagged traffic → VLAN 40
    bridge-vids 10 40

auto vmbr0.40                       ← CRITICAL: Management IP on VLAN 40
iface vmbr0.40 inet static
    address 192.168.40.60/24
    gateway 192.168.40.1

auto vmbr0.10                       ← Guest VLAN
iface vmbr0.10 inet static
    address 10.10.10.60/24
```

---

## Key Fixes Applied

| Aspect | Problem | Solution |
|--------|---------|----------|
| **vmbr0 mode** | Had `inet static` | Changed to `inet manual` |
| **vmbr0 IP** | Assigned to bridge | Moved to `vmbr0.40` interface |
| **Management access** | No interface for VLAN 40 | Created `auto vmbr0.40` with 192.168.40.60/24 |
| **Guest VLAN** | Incomplete setup | Kept `auto vmbr0.10` with 10.10.10.60/24 |
| **Hardware fix** | Missing persistence | Kept `post-up /sbin/ethtool` on nic1 |

---

## Two-Layer Fix Strategy

### Layer 1: Immediate (Race Condition Prevention)
When deploying, manually run this BEFORE `ifreload -a`:
```bash
/sbin/ethtool -K nic1 rx-vlan-filter off tx-vlan-offload off
```

This prevents the race condition where the bridge tries to process VLAN-tagged packets before the NIC's hardware offloading is disabled.

### Layer 2: Persistence (Reboot Stability)
The configuration file includes:
```
iface nic1 inet manual
    post-up /sbin/ethtool -K nic1 rx-vlan-filter off tx-vlan-offload off
```

This ensures that after a reboot, the ethtool fix is automatically re-applied.

---

## Why the Hardened Script Rolled Back

The `ugreen-vlan10-apply-hardened.sh` script had:
- ✅ Comprehensive verification
- ✅ Automatic rollback on failure
- ✅ Multiple safety checks

**But it was trying to apply a broken configuration.** The verification correctly detected that something was wrong and rolled back—this is the script working as designed, not a script failure.

The real issue was the **configuration file**, not the deployment script.

---

## Deployment Checklist

Before applying:
- [ ] Manual ethtool fix ready to run
- [ ] Dead man's switch (safety net) will be active
- [ ] Verification commands prepared
- [ ] All SSH sessions understood as potentially brief
- [ ] User has access to physical console if needed (optional but safer)

---

## Technical Notes

**Why bridge-pvid 40?**
- PVID (Primary VLAN ID) = the VLAN for untagged traffic
- Management traffic (SSH) is untagged
- Therefore, management must live on VLAN 40
- vmbr0.40 is the interface for VLAN 40 traffic

**Why vmbr0 is manual?**
- VLAN-aware bridges don't have their own IP
- They are packet switches, not endpoints
- All endpoints are on VLAN sub-interfaces (vmbr0.40, vmbr0.10, etc.)

**Why post-up ethtool?**
- UGREEN hardware has a bug: VLAN offloading enabled by default
- Disabled in hardware, processing moves to Linux kernel (reliable)
- post-up = runs after the interface comes up, persists across reboots

---

Generated: 2026-01-04 | Status: Ready for Deployment
