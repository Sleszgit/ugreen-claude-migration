# NFS Server Setup Issue - VLAN10 Access Problem

**Date:** 6 January 2026
**Issue:** NFS mount from VM100 (VLAN10) to UGREEN host consistently times out
**Goal:** Set up proper NFS access for future infrastructure machines on VLAN10

---

## Environment Setup

### UGREEN Proxmox Host Network Interfaces

**Management Network (Primary):**
```
Interface: vmbr0
IP: 192.168.40.60/24
Gateway: 192.168.40.1
Status: UP
```

**VLAN10 Infrastructure Network:**
```
Interface: vmbr0.10
IP: 10.10.10.60/24
Gateway: N/A (this IS the gateway for VLAN10)
Status: UP
```

Both interfaces are UP and reachable. Verified:
```bash
ip addr show | grep "inet"
# Returns both 192.168.40.60 and 10.10.10.60
```

---

## NFS Server Configuration

### Installation & Service Status

**Installed:** nfs-kernel-server on UGREEN host
**Status:** Running (verified with systemctl)

### Current Export Configuration

**File:** `/etc/exports`
```
/nvme2tb/lxc102scripts 10.10.10.0/24(rw,sync,no_subtree_check,no_root_squash)
```

**Export Applied:** Yes (verified with `sudo exportfs -ra`)
**Verification Output:**
```
/nvme2tb/lxc102scripts
10.10.10.0/24
```

### Directory Permissions

**Path:** `/nvme2tb/lxc102scripts/`
**Contents:** ~50+ files present and verified
**Owner:** 101000:101000 (LXC container user)
**Permissions:** drwxr-xr-x (755)

---

## VM100 Client Configuration

### Network Configuration

**Interface:** enp6s18
**IP Address:** 10.10.10.100/24
**Gateway:** 10.10.10.60 (UGREEN host on VLAN10)
**DNS:** 10.10.10.1 (corrected - was wrong initially)
**Status:** Verified with `ip addr show` - shows 10.10.10.100/24

### Network Connectivity Tests

**Ping Gateway:**
```bash
ping 10.10.10.60
# Works - ICMP reachable
```

**Traceroute:**
```bash
traceroute 10.10.10.60
# Shows direct connection on same subnet
```

**NFS Client:**
- nfs-common installed on VM100
- Mount point `/mnt/lxc102scripts` created

---

## The Problem: NFS Mount Timeouts

### Symptom

Mount command consistently times out on VM100:

```bash
sudo mount -t nfs 10.10.10.60:/nvme2tb/lxc102scripts /mnt/lxc102scripts -v

# Output:
mount.nfs: timeout set for Tue Jan  6 17:39:48 2026
mount.nfs: trying text-based options 'vers=4.2,addr=10.10.10.60,clientaddr=10.10.10.100'
# Then hangs indefinitely (Ctrl+C required)
```

### What This Means

The timeout indicates:
1. Network connectivity exists (VM100 can reach 10.10.10.60)
2. NFS RPC portmapper is NOT responding on 10.10.10.60
3. Either:
   - NFS services are only bound to 192.168.40.60 (management interface)
   - NFS services are not bound to 10.10.10.60 (VLAN10 interface)
   - Firewall rules blocking NFS ports between networks

---

## Technical Analysis

### NFS Service Binding Issue

**Hypothesis:** NFS services (rpcbind, nfsd, mountd) are bound ONLY to the primary management interface (192.168.40.60), not to the VLAN10 interface (10.10.10.60).

**Why This Happens:**
- Default NFS configuration typically binds to all interfaces or the primary interface
- When NFS starts, RPC portmapper (port 111) and NFS daemon (port 2049) listen on specific interfaces
- If not explicitly configured for multiple interfaces, they may only listen on the management network

**Evidence:**
```
Network connectivity: ✅ (ping works)
Export configured: ✅ (/etc/exports has entry)
Mount timeout: ✅ (RPC not responding)
→ RPC portmapper not listening on 10.10.10.60
```

---

## Potential Solutions to Investigate

### Option 1: Configure NFS to Bind to All Interfaces
**File:** `/etc/nfs.conf` or NFS daemon config
**Action:** Ensure RPC binds to 0.0.0.0 (all interfaces)

### Option 2: Configure NFS to Explicitly Bind to VLAN10
**File:** `/etc/nfs.conf`
**Action:** Specify `bind=10.10.10.60` for VLAN10-specific binding

### Option 3: Check Firewall Rules
**Issue:** Proxmox firewall might block NFS ports (111, 2049) between VLAN10 and management network
**Action:** Verify firewall rules allow:
- UDP 111 (rpcbind)
- TCP 111 (rpcbind)
- TCP 2049 (NFS)
- UDP 2049 (NFS)

### Option 4: Use NFSv3 Instead of NFSv4
**Action:** Mount with explicit NFS version:
```bash
mount -t nfs -o vers=3 10.10.10.60:/nvme2tb/lxc102scripts /mnt/lxc102scripts
```

### Option 5: Reconfigure NFS to Listen on Management IP and Add Firewall Rule
**Action:** Keep NFS on 192.168.40.60, add firewall rule to allow traffic from 10.10.10.0/24 to 192.168.40.60:2049

---

## Questions for Expert Review

1. **RPC Binding:** How do I configure NFS to bind/listen on BOTH 192.168.40.60 and 10.10.10.60?

2. **NFS Configuration Files:** What's the correct NFS configuration file to edit? (`/etc/nfs.conf`, `/etc/nfs/nfsd.conf`, `/etc/default/nfs-kernel-server`?)

3. **Multi-Interface Setup:** Is there a standard Proxmox pattern for NFS serving both management and VLAN networks?

4. **Firewall Rules:** What Proxmox firewall rules are needed to allow VLAN10→Management NFS traffic?

5. **Network Architecture:** Should NFS listen on:
   - Just 10.10.10.60 (VLAN10 only)?
   - Just 192.168.40.60 (management only) with firewall redirect?
   - Both interfaces?

6. **Best Practice:** For a homelab with multiple VLANs, what's the recommended NFS server architecture?

---

## Design Goals

**Primary Objective:** Allow all future infrastructure machines (VMs, containers, LXCs on various VLANs) to have read-only or read-write access to `/mnt/lxc102scripts` scripts directory.

**Architecture:**
- Central NFS server on UGREEN Proxmox host
- Multiple clients across different networks (management 192.168.40.0/24, VLAN10 10.10.10.0/24, future VLANs)
- Firewall rules properly configured for each network
- NFS exports properly scoped to allowed subnets

**Future Use Cases:**
- VM100 (VLAN10): Read-write access to install/run Phase 1b/1c scripts
- VM101+ (future): Access to shared scripts
- LXC103+ (future): Access to shared scripts
- Homelab sync: Maybe bidirectional sync with Homelab 192.168.40.40

---

## Current Blockers

1. ❌ Cannot execute `sudo` commands on UGREEN host via SSH (password-protected sudo, no TTY)
2. ❌ Cannot edit NFS configuration files directly from VM100
3. ❌ Cannot verify RPC bindings from VM100 (need netstat/ss on host)
4. ❌ Cannot view Proxmox firewall rules configuration

**Workaround Needed:** Provide detailed diagnostic commands and configuration changes that can be:
- Applied manually on Proxmox console
- Applied via Proxmox web UI
- Applied via SSH with pre-configured sudo access (no password prompt)

---

## Files & Locations

**UGREEN Host:**
- `/etc/exports` - NFS export configuration
- `/etc/nfs.conf` or `/etc/default/nfs-kernel-server` - NFS daemon config
- `/nvme2tb/lxc102scripts/` - Shared scripts directory

**VM100:**
- `/mnt/lxc102scripts/` - Mount point (currently empty/unmounted)
- `/etc/fstab` - Persistent mount config (not yet added)

---

## Timeline

**Session 98:** VM100 created successfully
**Session 99 (Current):** Attempting to set up NFS access from VLAN10
**Issue Discovered:** RPC timeout indicates NFS not listening on VLAN10 interface

---

**Status:** 🔴 BLOCKED - Awaiting expert diagnosis and NFS configuration solution

Generated: 6 January 2026, 17:45 CET
