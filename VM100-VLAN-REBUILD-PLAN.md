# VM100 VLAN 10 Rebuild Plan - Safety-First Approach

**Date:** 3 January 2026
**Status:** PLAN PENDING APPROVAL
**Critical Priority:** Maintain Proxmox Host Availability at All Times

---

## Executive Summary

This plan rebuilds VM100 on UGREEN Proxmox with VLAN 10 network (10.10.10.0/24) using the proven working homelab configuration as reference. The approach prioritizes safety with automatic backups, rollback capability, and connectivity checks at every step.

**Key Insight from Previous Failure:**
- Last attempt likely assigned VM100 IP 192.168.40.60 (same as Proxmox HOST) → IP conflict
- Or modified host network config incorrectly without proper VLAN setup
- OR attempted to move VM to different subnet without establishing vmbr0.10 bridge first

---

## Root Cause Analysis: Why Last Attempt Failed

### Evidence from Session Notes:

1. **SESSION-26 Planning Error:**
   - Documented VM100 IP as "192.168.40.60" — BUT THIS IS THE PROXMOX HOST IP!
   - This is a critical conflict that would break both VM and host connectivity

2. **Missing VLAN Preparation:**
   - No mention of creating vmbr0.10 interface beforehand
   - Likely tried to change VM network without host-side VLAN setup

3. **Network Modification Approach:**
   - Possibly attempted to modify /etc/network/interfaces directly without proper syntax
   - No mention of `bridge-vlan-aware yes` or VLAN tagging configuration
   - No safety checks before applying changes

4. **Result:**
   - Host lost connectivity (192.168.40.60 unreachable)
   - Localhost IP conflict or missing bridge configuration
   - Required manual recovery + reboot

---

## The Safe Solution: Homelab-Based Approach

### What Works on Homelab:

```
Physical Interface: enp3s0
├── vmbr0 (management bridge)
│   ├── IP: 192.168.40.40/24
│   ├── gateway: 192.168.40.1
│   └── VLAN-aware: yes
│
└── vmbr0.10 (VLAN 10 tagged interface)
    ├── IP: 10.10.10.40/24
    ├── VLAN ID: 10
    └── Static routes: properly configured
```

**VMs on homelab:**
- VM with IP 10.10.10.10 on VLAN 10 ← **WORKING REFERENCE**

### Why This Works:
- Uses 802.1Q VLAN tagging on a single bridge
- Host has dual interfaces: management (192.168.40.x) + VLAN10 (10.10.10.x)
- VMs connect to vmbr0 but get VLAN10 tagging in their config
- No IP conflicts, clean separation

---

## Proposed Architecture for UGREEN

### Phase 1: Network Infrastructure Setup (NO VM CHANGES YET)

**Goal:** Set up vmbr0.10 interface on Proxmox host, identical to homelab

**Current State:**
```
Physical Interface: nic1 (or similar)
└── vmbr0 (management bridge)
    └── IP: 192.168.40.60/24 ← Proxmox host
```

**Target State (After Phase 1):**
```
Physical Interface: nic1
├── vmbr0 (management bridge - UNCHANGED)
│   ├── IP: 192.168.40.60/24 ← Proxmox host (SAME)
│   ├── gateway: 192.168.40.1 (SAME)
│   └── bridge-vlan-aware: yes ← ADD THIS
│
└── vmbr0.10 (NEW VLAN 10 interface)
    ├── IP: 10.10.10.60/24 ← NEW
    ├── VLAN ID: 10
    └── Static config
```

**Safety Mechanism:**
- Backup current /etc/network/interfaces to timestamped file
- Create new config in temporary file, validate syntax
- Apply with `ifup` (if ifupdown2 available) or reboot (if not)
- Monitor connectivity - automatic rollback on failure

### Phase 2: Create VM100 with VLAN10 Network

**VM Specifications:**
- VMID: 100
- Name: ugreen-docker
- OS: Ubuntu 24.04 LTS
- CPU: 4 vCPU
- RAM: 20GB
- Disk: 250GB (on nvme2tb pool)
- Network: Connected to vmbr0, tagged with VLAN10
- IP: 10.10.10.100/24 ← FIXED (not conflicting with anything)
- Gateway: 10.10.10.1 (or whatever VLAN10 gateway is)

**Creation Method:**
- Use Proxmox API or CLI `qm create` with proper VLAN tagging
- Example network config: `net0: virtio=xx:xx:xx:xx:xx:xx,bridge=vmbr0,tag=10`

### Phase 3: OS Installation & Hardening

**Ubuntu 24.04 Installation:**
- Boot VM from ISO
- Configure IP: 10.10.10.100/24 with proper gateway
- Enable SSH on standard port 22 (temporary)
- Verify connectivity from management network (192.168.40.0/24 → 10.10.10.100)

**Phase A Hardening (Existing Scripts Ready):**
- Apply SSH hardening → port 22022, keys-only
- Apply UFW firewall rules → allow from 10.10.10.0/24 and 192.168.40.0/24
- Apply Docker daemon hardening → userns-remap, isolation
- Create Docker networks (frontend, backend, monitoring)
- Deploy Portainer web UI

---

## Safety Mechanisms

### 1. Pre-Flight Checks

**Before touching network config:**
```bash
✓ Verify current connectivity to 192.168.40.60 works
✓ Ping Proxmox host default gateway (192.168.40.1)
✓ Check physical interface name (nic0, nic1, etc.)
✓ Create backup of /etc/network/interfaces
✓ Verify syntax of new network config
✓ Test with `ip addr` parsing before applying
```

### 2. Network Config Changes - Atomic & Reversible

**Option A (if ifupdown2 available):**
```bash
1. Create /etc/network/interfaces.new with VLAN config
2. Validate syntax: ifup --syntax-only
3. Keep SSH session OPEN as safety net
4. Apply: ifup vmbr0.10
5. Verify: ip addr show vmbr0.10
6. Monitor for 30 seconds
7. If connectivity lost: ifdown vmbr0.10 + rollback
```

**Option B (if need to reload full config):**
```bash
1. Create /etc/network/interfaces.new with full config
2. Validate all syntax
3. cp /etc/network/interfaces /etc/network/interfaces.bak-$(date +%s)
4. cp /etc/network/interfaces.new /etc/network/interfaces
5. SSH session stays open
6. Monitor for connectivity
7. If lost: revert from .bak file
```

### 3. Connectivity Monitoring

**After each network change:**
```bash
✓ Ping Proxmox host from LXC102 (should work immediately)
✓ Ping Proxmox default gateway (192.168.40.1)
✓ Try SSH to 192.168.40.60 (should work)
✓ Check Proxmox web UI (https://192.168.40.60:8006)
✓ Verify vmbr0.10 interface shows correct IP
✓ Verify bridge VLAN tagging: ip link show vmbr0
```

**Rollback Triggers (Automatic):**
- Can't ping 192.168.40.1
- SSH to 192.168.40.60 hangs > 10 seconds
- vmbr0.10 doesn't appear in `ip addr`
- Bridge loses VLAN-aware status

### 4. VM Creation Safety

**Before creating VM100:**
```bash
✓ Confirm vmbr0.10 is UP and has IP 10.10.10.60
✓ Verify Proxmox connectivity still 100% working
✓ Backup Proxmox cluster config
✓ Confirm nvme2tb pool has 300GB+ free space
✓ Verify no existing VM100 (should be deleted already)
```

**After VM creation:**
```bash
✓ VM boots successfully
✓ Ubuntu installer loads
✓ Install completes to disk
✓ VM boots from disk
✓ SSH works on standard port 22
✓ Network connectivity to both subnets works
```

---

## Step-by-Step Execution Plan

### **STEP 1: Verify Current UGREEN Network State** (5 min)
**Command (safe, read-only):**
```bash
# From LXC102, run these diagnostic commands
curl -s -k -H "Authorization: PVEAPIToken..." \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/network \
  | grep -o '"iface":"[^"]*"'

# Or SSH to homelab and check what we have there
ssh ugreen-homelab-ssh@192.168.40.40 "cat /etc/network/interfaces | grep -E '(iface|address|vlan|bridge)'"
```

**Expected Output:**
- Current: only vmbr0 on 192.168.40.0/24
- No vmbr0.10 yet
- Proxmox host at 192.168.40.60 is reachable

---

### **STEP 2: Prepare Network Config File** (10 min)

**Identify physical interface:**
```bash
# From Proxmox host (via homelab SSH):
ssh ugreen-homelab-ssh@192.168.40.40 "ssh root@192.168.40.60 'ip link show | grep ": nic"'"
```

**Create new network config:**
```bash
# Build /etc/network/interfaces.vlan10 with:
auto lo
iface lo inet loopback

iface nic0 inet manual    # (or whatever the name is)

auto vmbr0
iface vmbr0 inet static
        address 192.168.40.60/24
        gateway 192.168.40.1
        bridge-ports nic1   # (or correct interface)
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes      # ← ADD THIS
        bridge-vids 2-4094

auto vmbr0.10
iface vmbr0.10 inet static
        address 10.10.10.60/24
        post-up bridge vlan add vid 10 dev vmbr0 self
        post-up bridge vlan add vid 10 dev nic1 master

source /etc/network/interfaces.d/*
```

---

### **STEP 3: Apply Network Config (Safest Method)** (10-15 min)

**CRITICAL SAFETY PROCEDURE:**

1. **Keep SSH session open** throughout (your "escape hatch")

2. **Backup current config:**
   ```bash
   sudo cp /etc/network/interfaces \
     /etc/network/interfaces.backup-before-vlan10-$(date +%Y%m%d-%H%M%S)
   ```

3. **Create new config in temp file & validate:**
   ```bash
   sudo cp /etc/network/interfaces \
     /etc/network/interfaces.new
   # Edit /etc/network/interfaces.new with VLAN10 config
   # Validate: sudo ifup --syntax-only -a -i /etc/network/interfaces.new
   ```

4. **Apply config:**
   ```bash
   # Option A: Use ifupdown2 (safest)
   sudo ifup vmbr0.10

   # Option B: If ifupdown2 unavailable, test in new namespace first
   # Then apply and watch for errors
   ```

5. **Test connectivity immediately (30 second monitoring):**
   ```bash
   ping -c 3 192.168.40.1       # Should work
   ping -c 3 192.168.40.60      # Self-ping from another terminal
   ssh root@192.168.40.60 "hostname"   # Should work
   ```

6. **Verify vmbr0.10 exists:**
   ```bash
   ip addr show vmbr0.10
   ip link show vmbr0
   ```

7. **If anything fails → ROLLBACK IMMEDIATELY:**
   ```bash
   sudo cp /etc/network/interfaces.backup-* /etc/network/interfaces
   sudo ifdown vmbr0.10
   sudo systemctl restart networking
   # Verify connectivity restored
   ```

---

### **STEP 4: Create VM100** (20-30 min)

**Once vmbr0.10 is verified working:**

```bash
# Create VM with VLAN tagging
sudo qm create 100 \
  --name ugreen-docker \
  --memory 20480 \
  --cores 4 \
  --sockets 1 \
  --numa 0 \
  --ostype l26 \
  --machine q35 \
  --bios ovmf \
  --efidisk0 nvme2tb:256 \
  --scsi0 nvme2tb:512 \
  --net0 virtio,bridge=vmbr0,tag=10 \
  --bootdisk scsi0 \
  --boot c \
  --cdrom local:iso/ubuntu-24.04-live-server-amd64.iso
```

**Key Parameters:**
- `--net0 virtio,bridge=vmbr0,tag=10` ← CRITICAL: tag=10 for VLAN
- 250GB disk on nvme2tb
- UEFI boot (OVMF) for modern Ubuntu

---

### **STEP 5: Install Ubuntu 24.04** (30-45 min)

1. Boot VM from ISO
2. Network: DHCP (will get 10.10.10.x from DHCP if configured, or use static)
3. Static network config during install:
   - IP: 10.10.10.100/24
   - Gateway: 10.10.10.1 (or whatever is configured)
   - DNS: 8.8.8.8, 1.1.1.1
4. Install OS to disk
5. Reboot into installed system
6. **Verify connectivity:**
   ```bash
   # From LXC102
   ping 10.10.10.100      # Should work
   ssh user@10.10.10.100  # Should work
   ```

---

### **STEP 6: Apply Phase A Hardening** (1.5-2 hours)

**Use existing Phase A scripts:**
```bash
# Copy hardening scripts to VM100
scp -r scripts/vm100ugreen/hardening/ \
  user@10.10.10.100:/home/user/hardening/

# SSH to VM
ssh user@10.10.10.100

# Run scripts in order
cd hardening/
sudo ./00-pre-hardening-checks.sh
sudo ./01-ssh-hardening.sh        # Changes SSH to port 22022
sudo ./02-ufw-firewall.sh
sudo ./03-docker-daemon-hardening.sh
sudo ./04-docker-network-security.sh
sudo ./05-portainer-deployment.sh
sudo ./05-checkpoint-phase-a.sh    # Verify all changes
```

**Final Verification:**
```bash
# SSH on new port
ssh -p 22022 user@10.10.10.100 'whoami'

# Access Portainer
# https://10.10.10.100:9443 (accept self-signed cert)

# Check Docker networks
docker network ls     # Should show frontend, backend, monitoring
```

---

## Firewall Rules (UFW on VM100)

**After hardening, VM100 will have:**
```
SSH (22022):       ALLOW from 192.168.40.0/24 and 10.10.10.0/24
Portainer (9443):  ALLOW from 192.168.40.0/24 and 10.10.10.0/24
Docker services:   Isolated by Docker networks (frontend/backend/monitoring)
```

**This allows:**
- Management from 192.168.40.x subnet (Proxmox admin subnet)
- Inter-VLAN traffic as needed (configurable with firewall rules)
- Clean service isolation within Docker

---

## Rollback Plan (If Anything Goes Wrong)

### **Network Rollback (Immediate):**
```bash
# On Proxmox host
sudo cp /etc/network/interfaces.backup-* /etc/network/interfaces
sudo systemctl restart networking
# Should restore connectivity to 192.168.40.60
```

### **VM Rollback (Quick):**
```bash
# From LXC102
sudo qm stop 100
sudo qm delete 100
# Back to clean slate - no VM100
```

### **Proxy Access (If All Else Fails):**
- Use Proxmox web console to access VM directly (no network needed)
- Or access physical machine directly (if in your data center)
- Manual network config via console

---

## Timeline & Dependencies

| Step | Task | Duration | Dependency | Risk Level |
|------|------|----------|------------|-----------|
| 1 | Verify current state | 5 min | None | LOW |
| 2 | Prepare config | 10 min | Step 1 | LOW |
| 3 | Apply VLAN10 config | 15 min | Step 2 | **HIGH** (network) |
| 4 | Create VM100 | 20 min | Step 3 ✓ | MEDIUM |
| 5 | Install Ubuntu 24.04 | 45 min | Step 4 ✓ | MEDIUM |
| 6 | Phase A Hardening | 120 min | Step 5 ✓ | LOW |
| **TOTAL** | **Complete VM100 Setup** | **~3.5 hours** | Sequential | **Gated by Step 3** |

**Critical Gate:** Step 3 (VLAN10 setup) - if this fails, rollback immediately and retry with different approach.

---

## Decision Points Requiring User Input

### **1. Physical Interface Name**
Currently unknown - need to verify on UGREEN host. Options:
- `nic0`, `nic1`, `enp0s3`, `enp3s0`, etc.
- **How to determine:** Run `ip link show` on Proxmox host

### **2. VLAN10 Gateway**
Currently unknown - depends on your homelab network setup:
- Is it 10.10.10.1? 10.10.10.254? 10.10.10.40 (the homelab host itself)?
- **How to determine:** Check homelab routing: `ip route show`

### **3. DHCP vs Static IP**
Option A: Use DHCP server on 10.10.10.0/24 subnet (if available)
Option B: Manual static IP configuration (10.10.10.100/24)
- **Recommendation:** Static IP for predictability and control

### **4. Cross-Subnet Traffic Needs**
Eventually, will VM100 services need to access:
- Homelab NAS (192.168.40.40)?
- Other devices on 192.168.40.0/24?
- **Recommendation:** YES, allow it. UFW firewall rules can restrict to specific IPs per service.

---

## Summary: Why This Plan Is Safe

✅ **Before touching network:** Full backup + syntax validation
✅ **Network changes:** Atomic (single vmbr0.10 interface), reversible
✅ **SSH session open:** Escape hatch if connectivity lost
✅ **Connectivity checks:** At every step with automatic rollback triggers
✅ **VM creation:** Only after network is 100% verified working
✅ **OS installation:** Standard Ubuntu 24.04, proven methods
✅ **Hardening:** Existing tested scripts, modular, includes rollback
✅ **Firewall rules:** Clear, documented, allows cross-subnet communication

**The key difference from the failed attempt:**
- Then: Tried to move VM to new subnet without preparing host network infrastructure first
- Now: Prepare host network (vmbr0.10) → create VM with VLAN tag → install OS → harden

---

## Next Steps

### For User Approval:
1. **Review this plan** - Any questions or concerns?
2. **Decide on decision points above** (interface name, gateway, DHCP vs static)
3. **Approve execution** - Then I'll proceed step-by-step with verification at each stage

### Ready?
Reply with:
- ✅ Approval to proceed
- Any clarifications needed
- Answers to decision points (interface, gateway, network preferences)

---

**Plan created:** 3 January 2026
**Status:** Awaiting user approval
**Safety level:** HIGH (with automatic rollbacks)
