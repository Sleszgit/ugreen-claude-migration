# Session 105: VLAN-Aware Bridge Root Cause Identified

**Date:** 10 January 2026
**Time:** 04:00 - 04:50 CET
**Status:** ✅ ROOT CAUSE FOUND & FIX STAGED (Awaiting Restart)
**Duration:** ~50 minutes

---

## Executive Summary

Successfully identified the root cause of cross-VLAN connectivity failure: **VLAN-aware bridge isolation**. LXC102 was on VLAN 1 while VM100 was on VLAN 10, making them unreachable despite correct routing and firewall configuration. Created comprehensive diagnostic scripts and prepared the fix (adding `tag=10` to LXC102 network config).

---

## Objectives & Progress

### ✅ Completed

1. **VM100 Diagnostics Run**
   - Ran comprehensive network diagnostics on VM100
   - Confirmed interface UP, routes correct, gateway reachable
   - Showed asymmetric connectivity: gateway (VLAN10 router) reachable, but LXC102 unreachable

2. **UGREEN Host Packet Analysis**
   - tcpdump on vmbr0 showed NO ICMP packets from LXC102 to VM100
   - Confirmed packets not leaving container at all
   - Ruled out host-side firewall or routing issues

3. **LXC102 Interface Diagnostics**
   - Verified eth0 UP with no RX/TX drops
   - Route correctly configured: `10.10.10.0/24 via 192.168.40.60`
   - Gateway ping works (0% loss)
   - UFW confirmed inactive (not the blocker)

4. **Created Diagnostic Scripts**
   - `vm100-network-diagnostics.sh` - Comprehensive network check for VMs
   - `lxc102-iptables-diagnostics.sh` - Iptables rule inspection
   - `diagnose-vlan-bridge.sh` - VLAN bridge configuration analysis

5. **VLAN Bridge Analysis**
   - Discovered `bridge-vlan-aware yes` is enabled on vmbr0
   - Ran `bridge vlan show` and found:
     - `veth102i0` (LXC102): **VLAN 1** (untagged) ❌
     - `tap100i0` (VM100): **VLAN 10** (tagged) ✅
   - With VLAN filtering, these are isolated networks

6. **Root Cause Identified & Fix Staged**
   - LXC102 not a member of VLAN 10
   - Fix: Add `tag=10` to `/etc/pve/lxc/102.conf` net0 configuration
   - Command prepared: Edit net0 line to include `tag=10`

---

## Technical Investigation

### Bridge VLAN Configuration

**Current State (BROKEN):**
```
veth102i0 (LXC102 interface):  VLAN 1 (untagged)
tap100i0 (VM100 interface):    VLAN 10 (tagged)
```

With `bridge-vlan-aware yes`, the bridge only forwards traffic between ports on the **same VLAN**. LXC102 and VM100 are on different VLANs → isolated.

### LXC102 Configuration

**Before Fix:**
```
net0: name=eth0,bridge=vmbr0,gw=192.168.40.1,hwaddr=BC:24:11:F2:74:C4,ip=192.168.40.82/24,type=veth
```

**After Fix (Staged):**
```
net0: name=eth0,bridge=vmbr0,tag=10,gw=192.168.40.1,hwaddr=BC:24:11:F2:74:C4,ip=192.168.40.82/24,type=veth
```

The `tag=10` parameter tells Proxmox to add LXC102 to VLAN 10 on the bridge.

### Why Previous Diagnostics Missed This

1. **Gateway ping worked** - Packets to 192.168.40.60 succeeded because:
   - VLAN 1 can reach the host's management interface
   - Kernel connection tracking allows replies on established connections

2. **Tcpdump showed nothing** - Packets never left container because:
   - With VLAN-aware bridge, packets destined for different VLAN are dropped at bridge
   - No iptables rule needed; filtering happens at bridge level
   - Appeared to be container-level block, but was actually bridge-level VLAN isolation

---

## Diagnostic Outputs

### VM100 Network Status
- Interface: `enp6s18` UP (1500 MTU)
- IP: `10.10.10.100/24`
- Gateway: `10.10.10.1` reachable (✅ ping works)
- Routes: Default via 10.10.10.1
- rp_filter: 2 (loose mode)
- UFW: Inactive
- iptables FORWARD: Docker chains present
- **LXC102 unreachable:** ❌ (timeout)
- **UGREEN gateway unreachable:** ❌ (timeout)

### LXC102 Network Status
- Interface: `eth0` UP (1500 MTU)
- IP: `192.168.40.82/24`
- Routes: Configured with VLAN10 static route
- Gateway: `192.168.40.60` reachable (✅ ping works)
- rp_filter: 2 (loose mode)
- UFW: Inactive
- No iptables rules blocking traffic
- **VLAN10 VM unreachable:** ❌ (timeout)

### UGREEN tcpdump Results
```
- ✅ ARP working (VM100 requesting UGREEN VLAN10 MAC)
- ❌ Zero ICMP packets from 192.168.40.82 to 10.10.10.100
- ❌ No ping requests appearing on vmbr0
- ✅ Other traffic visible (external SSH, etc.)
```

**Conclusion:** Packets not even reaching the bridge from LXC102 due to VLAN isolation.

---

## Session Discoveries

### Key Insight
When VLAN-aware bridge is enabled, the bridge itself enforces VLAN membership. A port on VLAN 1 cannot communicate with a port on VLAN 10, **regardless of routing or firewall configuration**. This is a bridge-level forwarding decision, not an IP-level one.

### Why This Matters
- IP routing looks correct at container level
- Firewall rules appear acceptable
- But bridge-level VLAN membership silently blocks traffic
- tcpdump at container level shows no packets (they're dropped at bridge)
- tcpdump at host level shows nothing leaving the veth interface

---

## Files & Configs Modified

| Item | Status | Note |
|------|--------|------|
| /etc/pve/lxc/102.conf | 🟡 STAGED | `tag=10` added to net0 (pending restart) |
| /etc/systemd/network/eth0.network | ✅ Session 104 | VLAN10 static route added |
| vm100-network-diagnostics.sh | ✅ Created | Comprehensive VM network diagnostics |
| diagnose-vlan-bridge.sh | ✅ Created | VLAN bridge configuration analyzer |
| lxc102-iptables-diagnostics.sh | ✅ Created | iptables rule inspector |

---

## Next Steps

### Immediate (After Restart Approval)
1. **Restart LXC102** to apply VLAN tag change
   ```bash
   sudo pct reboot 102
   ```

2. **Verify VLAN membership** changed:
   ```bash
   sudo bash -c "bridge vlan show | grep veth102i0"
   # Expected: veth102i0         10 PVID Egress Untagged
   ```

3. **Test connectivity** from LXC102:
   ```bash
   ping 10.10.10.100
   ```

4. **Test reverse connectivity** from VM100:
   ```bash
   ping 192.168.40.82
   ```

### If Tests Pass
- Cross-VLAN communication will be restored
- Both ping directions should work
- Applications can communicate across VLANs

### Potential Additional Issues
- If management traffic (192.168.40.0/24) fails after restart, LXC102 might need to be on multiple VLANs (VLAN 1 + VLAN 10)
- Current fix adds `tag=10` which might isolate from VLAN 40 traffic

---

## Session Lessons

1. **VLAN-Aware Bridge Changes Everything**
   - Not just about routing and firewalls
   - Bridge-level VLAN membership is a separate filtering layer
   - Linux bridge can silently drop packets based on VLAN membership

2. **tcpdump Limitations**
   - tcpdump at container level won't show bridge-dropped packets
   - Must tcpdump at multiple layers to diagnose VLAN issues
   - Packets dropped at bridge don't reach veth interface

3. **Proxmox VLAN Configuration**
   - LXC containers can have `tag=X` parameter to join VLANs
   - VMs use `tag=X` in their config
   - Untagged ports are on VLAN 1 by default

4. **Asymmetric Connectivity**
   - Gateway ping works because VLAN 1 ↔ management interface
   - Cross-VLAN fails because bridge isolates VLAN 1 and VLAN 10
   - Reveals the root cause once understood

---

## GitHub Commit

```
commit: SESSION-105-VLAN-AWARE-BRIDGE-ROOT-CAUSE
message: Session 105: Root cause found - VLAN-aware bridge isolation

✅ IDENTIFIED: LXC102 on VLAN 1, VM100 on VLAN 10 - isolated by bridge

KEY FINDINGS:
- bridge vlan show revealed: veth102i0 VLAN 1, tap100i0 VLAN 10
- With bridge-vlan-aware yes, different VLANs cannot communicate
- Packets stopped at bridge, not firewall or routing
- Fix: Add tag=10 to LXC102 net0 in /etc/pve/lxc/102.conf

DIAGNOSTICS CREATED:
- vm100-network-diagnostics.sh (comprehensive VM network check)
- diagnose-vlan-bridge.sh (VLAN bridge configuration)
- lxc102-iptables-diagnostics.sh (iptables inspection)

FIX STAGED: /etc/pve/lxc/102.conf updated with tag=10
AWAITING: Restart approval before testing connectivity
```

---

**Status:** ⏳ Session 105 Complete - Fix Staged, Awaiting Restart
**Next:** User approval to restart LXC102 and test
**Estimated Effort:** ~5 minutes to restart and verify

🤖 Generated with Claude Code
Session 105: VLAN-Aware Bridge Root Cause Analysis
10 January 2026 04:50 CET
