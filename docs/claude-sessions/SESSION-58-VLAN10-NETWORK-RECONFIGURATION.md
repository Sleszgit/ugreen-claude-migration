# SESSION 58: VLAN 10 Network Reconfiguration for VM 100

**Date:** 29 Dec 2025
**Status:** 🟡 IN PROGRESS - VLAN 10 Setup
**Location:** UGREEN LXC 102 & VM 100
**Device:** UGREEN DXP4800+ Proxmox (192.168.40.60)

---

## 📋 Session Summary

Working on reconfiguring VM 100 network from isolated management network (192.168.40.102) to shared container VLAN 10 (10.10.10.100) alongside homelab VM 100 (10.10.10.10).

---

## ✅ What's Been Done

### Phase B Scripts (100% Complete)
- ✅ Created 7 Phase B hardening scripts (3,637 lines total)
- ✅ Deployed all scripts to VM 100 at `~/vm100-hardening/`
- ✅ Scripts ready for execution when network is finalized

Scripts deployed:
- 06-kernel-security.sh (366 lines)
- 07-fail2ban-setup.sh (338 lines)
- 08-apparmor-profiles.sh (395 lines)
- 09-seccomp-profiles.sh (1,447 lines)
- 10-docker-bench.sh (128 lines)
- 11-checkpoint-phase-b.sh (341 lines)
- README-PHASE-B.md (622 lines)

### Network Architecture Decision (Complete)
✅ Analyzed both homelab and UGREEN setups:
- **Homelab:** VLAN 10 at 10.10.10.0/24 with VM 100 at 10.10.10.10
- **UGREEN Management:** 192.168.40.0/24 (Proxmox host at .60, LXC 102 at .82, VM 100 at .102)

✅ **Decision:** Move UGREEN VM 100 to VLAN 10 (10.10.10.100)
- Rationale: Unified container network across both environments
- Security: Separates container traffic from management traffic
- Scalability: Single VLAN for future containers on both systems

---

## 🟡 Current Status: VLAN 10 Configuration

### First Attempt (Partial Success)
Ran: `sudo bash /nvme2tb/lxc102scripts/ugreen-vlan10-setup.sh`

**Results:**
- ✅ Step 1-8: Network configuration successful
  - vmbr0.10 interface created and UP: `inet 10.10.10.40/24`
  - Backup file created: `/etc/network/interfaces.backup.20251229-063549`

- ❌ Step 10: VM 100 network modification FAILED
  - Error: `hotplug problem - bridge 'vmbr0.10' is neither a linux nor an OVS bridge!`
  - Root cause: vmbr0.10 was created as a VLAN interface, not as a Linux bridge device
  - Proxmox requires actual bridge device with `bridge-ports`, `bridge-stp`, `bridge-fd` parameters

### Solution: Fixed Script Created
**File:** `/mnt/lxc102scripts/ugreen-vlan10-setup-fixed.sh`

**Key Changes:**
- Creates vmbr0.10 as a proper Linux **bridge device** (not just VLAN interface)
- Adds correct bridge parameters:
  ```
  auto vmbr0.10
  iface vmbr0.10 inet manual
      bridge-ports none
      bridge-stp off
      bridge-fd 0
      vlan-raw-device vmbr0

  auto vmbr0.10:0
  iface vmbr0.10:0 inet static
      address 10.10.10.40/24
  ```
- This satisfies Proxmox's requirement for bridge devices

---

## 📍 Current Network Configuration

### UGREEN Proxmox Host
```
Management Network: 192.168.40.0/24
├── vmbr0: Bridge (main management)
│   ├── Address: 192.168.40.60/24
│   └── Ports: nic0, nic1
├── vmbr0.10: Bridge (VLAN 10) ← IN PROGRESS
│   └── Address: 10.10.10.40/24 (gateway for VLAN 10)
```

### VM 100 (Current → Target)
```
Current:
- IP: 192.168.40.102
- Network: eth0 connected to vmbr0 (untagged)
- SSH Port: 22022 (open on management network)

Target:
- IP: 10.10.10.100
- Network: eth0 connected to vmbr0.10 (VLAN tagged)
- SSH Port: 22022 (accessible from VLAN 10)
- Access: Via LXC 102 (both on VLAN 10) or homelab (also on VLAN 10)
```

### Homelab (Reference)
```
VLAN 10 Network: 10.10.10.0/24
├── VM 100: 10.10.10.10 (Kavita server)
└── Gateway: 10.10.10.1
```

---

## 📝 Next Steps (Exact Order)

### IMMEDIATE (When User Runs on UGREEN Host)
1. First: **Restore from backup** (old script partially modified config)
   ```bash
   sudo cp /etc/network/interfaces.backup.20251229-063549 /etc/network/interfaces
   sudo systemctl restart networking
   ```

2. Then: **Run fixed script**
   ```bash
   sudo bash /nvme2tb/lxc102scripts/ugreen-vlan10-setup-fixed.sh
   ```

3. **Verify output** - Script should complete all 13 steps without errors

### AFTER Script Completes (1-2 minutes)

#### Configure VM 100 Internal IP (from LXC 102)
```bash
ssh -p 22022 sleszdockerugreen@10.10.10.100 << 'EOF'
# (Will fail initially - VM may still be rebooting)
# Wait 1-2 minutes for VM to fully boot on new network
EOF
```

#### Update VM 100 Network Interface
Edit `/etc/network/interfaces` on VM 100:
```bash
# Replace 192.168.40.x references with 10.10.10.100
# Keep subnet mask /24
# Gateway should be 10.10.10.1 (from homelab/UGREEN VLAN 10 gateway)
```

#### Restart Networking on VM 100
```bash
sudo systemctl restart networking
```

#### Test Connectivity
From LXC 102:
```bash
ping 10.10.10.100
ssh -p 22022 sleszdockerugreen@10.10.10.100
```

### THEN: Execute Phase B Scripts
Once VM 100 is fully on VLAN 10 and accessible:
```bash
ssh -p 22022 sleszdockerugreen@10.10.10.100
cd ~/vm100-hardening/

# Run scripts sequentially
bash 06-kernel-security.sh
bash 07-fail2ban-setup.sh
bash 08-apparmor-profiles.sh
bash 09-seccomp-profiles.sh
bash 10-docker-bench.sh
bash 11-checkpoint-phase-b.sh
```

Estimated duration: 2.5-3 hours

---

## 🔧 Key Files & Scripts

| File | Location | Status | Purpose |
|------|----------|--------|---------|
| ugreen-vlan10-setup-fixed.sh | /mnt/lxc102scripts/ | ✅ Ready | VLAN 10 bridge setup (FIXED) |
| Phase B Scripts | ~/vm100-hardening/ on VM 100 | ✅ Deployed | System hardening (7 scripts) |
| Network Backup | /etc/network/interfaces.backup.20251229-063549 | ✅ Safe | Rollback point if needed |

---

## ⚠️ Important Notes

1. **Network Isolation:** After VLAN 10 setup:
   - VM 100 will ONLY be accessible from VLAN 10
   - Management network (192.168.40.x) cannot directly access VM 100
   - Access must go through LXC 102 (which bridges both networks) or homelab

2. **Routing:**
   - LXC 102 can access both networks (192.168.40.x and 10.10.10.x)
   - Use LXC 102 as SSH jump point if needed

3. **Firewall:**
   - VLAN 10 gateway is 10.10.10.1 (managed by UniFi)
   - Phase B fail2ban will be configured for new network

4. **Rollback Plan:**
   - If anything fails, restore from backup:
   ```bash
   sudo cp /etc/network/interfaces.backup.20251229-063549 /etc/network/interfaces
   sudo systemctl restart networking
   ```

---

## 📊 Session Statistics

- **Phase B Scripts Created:** 7 (3,637 lines)
- **Phase B Scripts Deployed:** 7 ✅
- **Network Architecture Analyzed:** ✅
- **VLAN 10 Bridge Script:** 1 (initial), 1 (fixed) 🟡 In Progress
- **Time Spent:** ~30 minutes

---

## 🔗 Related Sessions

- **SESSION 57:** Phase B hardening scripts creation (70% → 100% complete)
- **SESSION 56:** Phase A hardening execution (VM 100 at 192.168.40.102)
- **SESSION 45:** Homelab SSH access (completed)

---

**Last Updated:** 29 Dec 2025, 06:45 UTC
**Current Activity:** Awaiting user execution of VLAN setup script on UGREEN Proxmox host

