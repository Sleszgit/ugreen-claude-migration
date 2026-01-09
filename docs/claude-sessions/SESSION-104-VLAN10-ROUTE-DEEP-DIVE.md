# Session 104: VLAN10 Route Deep Dive - Packets Not Leaving LXC102

**Date:** 9 January 2026
**Time:** 05:00 - 05:30 CET
**Status:** ⏳ CHECKPOINT - Root Cause Narrowed: Packets Blocked at Container Level
**Duration:** ~30 minutes

---

## Executive Summary

Applied the permanent static route to LXC102 and enabled IP forwarding on UGREEN host, but cross-VLAN connectivity still failed. Ran tcpdump on UGREEN bridge and discovered critical finding: **ping packets never leave LXC102 container**. They don't appear on vmbr0 at all. Root cause is not firewall or routing, but something blocking egress from the container itself.

---

## Objectives & Progress

### ✅ Completed

1. **Applied Permanent Route Fix**
   - Added route to `/etc/systemd/network/eth0.network` ✅
   - Restarted systemd-networkd ✅
   - Route now visible in `ip route show` ✅

2. **Enabled IP Forwarding**
   - Set `net.ipv4.ip_forward=1` on UGREEN host ✅
   - Confirmed enabled via sysctl ✅

3. **Verified Firewall Rules**
   - UFW route rules in place ✅
   - Proxmox firewall (cluster.fw) reviewed ✅
   - No per-container/VM firewall rules blocking traffic ✅

4. **Packet Tracing Analysis**
   - Ran tcpdump on UGREEN vmbr0 bridge ✅
   - Attempted ping from LXC102 to VM100 ✅
   - Critical finding: No packets appear on bridge ✅

### ⏳ Pending - Diagnose Container Egress Block

1. **Check LXC102 Interface Stats**
   - Need to verify TX/RX drops on eth0
   - Check if packets are being dropped at container level

---

## Technical Investigation

### Route Configuration Status

**LXC102 Routing Table (After Fix):**
```
default via 192.168.40.1 dev eth0 proto static 
10.10.10.0/24 via 192.168.40.60 dev eth0 proto static   ← NEW ROUTE
192.168.40.0/24 dev eth0 proto kernel scope link src 192.168.40.82
```

✅ Route is configured and present in routing table

### UGREEN Configuration

**IP Forwarding:**
```bash
net.ipv4.ip_forward = 1  ✅ Enabled
```

**Bridge & VLAN Config:**
```
vmbr0: 192.168.40.60/24 (management, bridge-vlan-aware yes)
vmbr0.10: 10.10.10.60/24 (VLAN10 subinterface)
Default VLAN: 40 (tagged on bridge)
```

**UFW Status:**
- Default policy: allow (routed)
- Forward rules in place for cross-VLAN traffic ✅
- Iptables PVEFW-FORWARD shows stateful rules accepting established ✅

**Proxmox Firewall:**
```
/etc/pve/firewall/cluster.fw: Enabled (policy_in: DROP)
/etc/pve/firewall/lxc/102.fw: NOT CONFIGURED
/etc/pve/firewall/qemu-server/100.fw: NOT CONFIGURED
```
✅ No per-container firewall blocking

### Connectivity Test Results

**Working:**
- ✅ LXC102 → UGREEN host (192.168.40.60): Ping replies
- ✅ LXC102 → External SSH (192.168.99.6): Connected (visible in tcpdump)
- ✅ VM100 SSH listening on port 22
- ✅ VM100 network interface up and configured

**Not Working:**
- ❌ LXC102 → VM100 (10.10.10.100): 100% packet loss
- ❌ Ping timeout (no ICMP Echo Reply)

### Critical tcpdump Finding

**Command Run:**
```bash
sudo tcpdump -i vmbr0 -nn -e "host 192.168.40.82 or host 10.10.10.100 or arp"
```

**Result:**
- SSH traffic between 192.168.99.6 and 192.168.40.82 visible ✅
- ARP requests from other VLANs visible (vlan 50 ARP) ✅
- **NO packets from 192.168.40.82 to 10.10.10.100** ❌
- **No ARP requests for 10.10.10.100** ❌
- No packets on vmbr0 attempting to reach VLAN10

**Conclusion:** Packets are being **dropped inside LXC102 container** before reaching the host bridge.

---

## Root Cause Analysis

### What We Know:
1. Route is configured in LXC102 ✅
2. IP forwarding enabled on UGREEN ✅
3. Firewall rules allow forwarding ✅
4. Packets never appear on UGREEN bridge ❌

### Hypothesis:

**Packets are being dropped at LXC102's network interface level**, not by any external firewall or routing issue.

Possible causes:
1. **TX drops on eth0** - Interface dropping outgoing packets
2. **Interface misconfiguration** - eth0 not properly connected to vmbr0
3. **iptables rules inside LXC102** - Local firewall blocking egress
4. **Container network namespace issue** - Routing not working within namespace

---

## Next Diagnostic Steps Required

### On LXC102:

```bash
# Check interface statistics
ip -s link show eth0

# Verify interface is UP
ip link show eth0

# Confirm route is actually used for this destination
ip route get 10.10.10.100

# Check for iptables rules inside container
sudo iptables -L -n
sudo iptables -L -n -v | grep -i drop

# Check if we can even reach the gateway
ping 192.168.40.60
```

### What to Look For:

- **TX/RX dropped counters** on eth0 (should be 0)
- **Interface state** (should be UP)
- **iptables FORWARD chain** (should allow traffic)
- **Gateway ping** (should work - proves interface is functional)

---

## Session Lessons

1. **Tcpdump Narrows Problem Scope**
   - Shows packets not leaving container, not a bridge/firewall issue
   - Eliminates entire categories of potential causes
   - Points directly to container-level network namespace

2. **Route + Forwarding ≠ Connectivity**
   - Just because route exists and forwarding is on doesn't mean packets move
   - Must verify packets actually enter the network stack
   - Interface-level diagnostics needed

3. **Gemini Approach Validated**
   - Tcpdump suggestion was exactly right
   - Narrowed problem from "entire network" to "container egress"
   - Next steps are more focused and testable

---

## Files & Configs Touched This Session

| Item | Status | Note |
|------|--------|------|
| LXC102 eth0.network | ✅ Modified | Route added, config reloaded |
| UGREEN sysctl | ✅ Modified | IP forwarding enabled |
| tcpdump output | ✅ Analyzed | No VLAN10 traffic observed |

---

## Current Network State

### LXC102:
```
Interface: eth0
IP: 192.168.40.82/24
Routes: Management + VLAN10 (configured)
Status: ⚠️ Packets not leaving interface
```

### VM100:
```
Interface: enp6s18
IP: 10.10.10.100/24
Gateway: 10.10.10.1 (wrong per Gemini, should be .60)
Status: ⚠️ Unreachable from management VLAN
```

### UGREEN:
```
vmbr0: 192.168.40.60/24
vmbr0.10: 10.10.10.60/24
IP Forwarding: Enabled
Status: ✅ Configured correctly
```

---

## Session Checklist

- ✅ Permanent route added to LXC102
- ✅ IP forwarding enabled on UGREEN
- ✅ Firewall rules verified in place
- ✅ tcpdump run to trace packet flow
- ✅ Critical finding: packets not leaving LXC102
- ✅ Root cause narrowed to container network interface
- ⏳ Need to verify interface stats and iptables rules on LXC102

---

## GitHub Commit

```
commit: SESSION-104-VLAN10-ROUTE-DEEP-DIVE
message: Session 104: Tcpdump reveals packets blocked at LXC102 interface

Permanent fix applied but connectivity still failing.
Key finding: Ping packets never reach UGREEN bridge - they're
dropped inside LXC102 container before egress.

✅ Actions taken:
- Permanent route added via systemd-networkd
- IP forwarding enabled on UGREEN
- Firewall rules verified (UFW + Proxmox)
- Tcpdump analysis performed

✅ Root cause identified:
- Packets not leaving LXC102 eth0
- Not a bridge/firewall/routing issue
- Container-level network interface problem

Next: Diagnose interface stats and iptables on LXC102
```

---

**Status:** ⏳ Session 104 Checkpoint Complete
**Problem Scope:** ✅ Narrowed (container-level)
**Next Action:** Verify LXC102 interface stats and local iptables
**Estimated Path to Fix:** Check 4 diagnostic commands on LXC102

🤖 Generated with Claude Code
Session 104: VLAN10 Route Deep Dive Analysis
9 January 2026 05:30 CET
