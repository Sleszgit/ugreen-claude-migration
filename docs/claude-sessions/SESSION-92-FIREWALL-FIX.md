# Session 92: UGREEN Firewall Fix - TCP Connectivity Restored

**Date:** 5 Jan 2026 14:30-15:00 CET
**Issue:** LXC 102 could not reach UGREEN Proxmox host on TCP ports 22022 (SSH) and 8006 (API) - timeouts
**Root Cause:** Firewall configuration had unsupported iptables syntax causing parse errors
**Status:** ✅ RESOLVED

---

## Problem Analysis

### Initial State (Phase 1 Diagnostics)
- ✅ ICMP to 192.168.40.60: Working (0% packet loss)
- ❌ TCP 22022: Connection timeout
- ❌ TCP 8006: Connection timeout
- **Hypothesis:** Network layer working, TCP layer blocked by firewall

### Root Cause Found (Phase 2)
Firewall config at `/etc/pve/firewall/cluster.fw` had syntax errors:
```
- Line 5: Invalid option log_level_in: info
- Lines 16-17: Unsupported iptables syntax (-m conntrack --ctstate ESTABLISHED,RELATED)
```

When Proxmox firewall fails to parse rules, it enters **fail-close state** = blocks all TCP traffic.

---

## Solution Implemented

### 1. Created Fix Script
**Location:** `/mnt/lxc102scripts/fix-proxmox-firewall.sh`

**Script features:**
- Backs up current config to `/root/firewall-backups/`
- Writes corrected config with pure Proxmox firewall syntax
- Uses aggressive restart (systemctl stop/start) for clean reload
- Validates firewall started without parsing errors
- Shows recovery instructions if rollback needed

### 2. Corrected Firewall Rules
**Removed unsupported syntax:**
- ❌ `log_level_in: info` (invalid)
- ❌ `-m conntrack --ctstate ESTABLISHED,RELATED` (iptables, not Proxmox)
- ❌ Multiple duplicate rules causing confusion

**Applied proper rule order:**
1. ICMP allow (ping)
2. Localhost allow (127.0.0.1, ::1)
3. Specific allow rules (from trusted IPs/sources)
4. DROP rule at end (catch-all)

**Final rule set:**
- SSH (port 22) & API (port 8006) from 192.168.99.6 (trusted desktop)
- SSH (port 22022) & API (port 8006) from 192.168.40.82 (LXC 102)
- SSH (port 22) & API (port 8006) from 192.168.40.40 (Homelab - currently offline)

---

## Results

### Phase 3 Verification (Post-Fix)
```
✅ SSH (192.168.40.60:22022) - Connection succeeded
✅ API (192.168.40.60:8006)  - Connection succeeded
🔌 Homelab (192.168.40.40)   - Powered off (no route = expected)
```

### Service Status
```
✓ pve-firewall running without errors
✓ sshd listening on 0.0.0.0:22022 and [::]:22022
✓ pveproxy listening on *:8006
✓ No parsing errors in recent logs
```

---

## Files Modified

1. **Created:** `/mnt/lxc102scripts/fix-proxmox-firewall.sh`
   - Production-ready firewall fix script
   - Safe backup mechanism
   - Validation checks

2. **Modified:** `/etc/pve/firewall/cluster.fw`
   - Cleaned up syntax errors
   - Removed unsupported rules
   - Proper rule ordering
   - Backup at: `/root/firewall-backups/cluster.fw.backup.20260105-144442`

---

## Lessons Learned

1. **Proxmox firewall ≠ iptables**
   - Proxmox has its own firewall syntax
   - Many iptables features not supported (-m, --ctstate, log_level_in with value)
   - Fail-close on parse errors is aggressive but safe

2. **Rule ordering matters**
   - DROP rules block everything after them
   - Must order: allow specific → drop default
   - Not like iptables where rules are processed sequentially

3. **Log interpretation**
   - journalctl shows historical logs
   - Old errors persist in journal even after fixes
   - Must verify fresh restart to see current state

---

## Recovery Instructions

If rollback needed:
```bash
sudo cp /root/firewall-backups/cluster.fw.backup.20260105-144442 /etc/pve/firewall/cluster.fw
sudo pve-firewall restart
```

Or re-run the fix script:
```bash
sudo /nvme2tb/lxc102scripts/fix-proxmox-firewall.sh
```

---

## Next Steps

- [ ] Monitor firewall stability for 24 hours
- [ ] Set up VLAN10 when ready (separate task)
- [ ] Document firewall rules in infrastructure guide
- [ ] Consider adding more restricted rules by VPC/VLAN

---

**Session completed successfully. All TCP connectivity to UGREEN host restored.**
