# Homelab NFS Mount Issue - Complete Analysis for Gemini

**Date:** 2026-01-01
**Problem:** NFS mount from UGREEN Proxmox to Homelab Proxmox fails with "access denied by server"
**Status:** Configuration appears valid, but authentication fails

---

## System Architecture

**Homelab (NFS Server):**
- Host: Proxmox VE (192.168.40.40)
- User: sshadmin (Debian system user)
- NFS Server: Active and running
- Firewall: pve-firewall (enabled)

**UGREEN (NFS Client):**
- Host: Proxmox VE (192.168.40.60)
- Trying to mount NFS export
- Network: Same subnet (192.168.40.0/24)
- Direct connectivity: OK (SSH works between systems)

---

## NFS Configuration on Homelab (Server)

### Export Rule
**File:** `/etc/exports`
```
/mnt/homelab-backups/lxc102-vzdump 192.168.40.60(rw,sync,no_subtree_check,sec=sys,insecure,no_root_squash,no_all_squash)
```

### Export Verification
```bash
$ sudo exportfs -v
/mnt/homelab-backups/lxc102-vzdump
                192.168.40.60(sync,wdelay,hide,no_subtree_check,sec=sys,rw,insecure,no_root_squash,no_all_squash)
```

**Status:** ✅ Export registered and showing correct options

### Directory Setup
```bash
$ ls -lad /mnt/homelab-backups/lxc102-vzdump
drwxr-xr-x 2 nobody nogroup 4096 Jan  1 18:02 /mnt/homelab-backups/lxc102-vzdump
```

**Status:** ✅ Directory exists with correct permissions

### Firewall Rules
Added to `/etc/pve/firewall/cluster.fw`:
```
IN ACCEPT -p tcp -dport 111 -source 192.168.40.60
IN ACCEPT -p udp -dport 111 -source 192.168.40.60
IN ACCEPT -p tcp -dport 2049 -source 192.168.40.60
IN ACCEPT -p udp -dport 2049 -source 192.168.40.60
IN ACCEPT -p tcp -dport 20048 -source 192.168.40.60
IN ACCEPT -p udp -dport 20048 -source 192.168.40.60
```

**Status:** ✅ Firewall rules installed and reloaded

### NFS Services Status
```
nfs-server.service:   Active: active (exited)
rpc.mountd:           Active: active (running)
nfsd:                 Running (8 threads)
rpcbind:              Running
```

**Status:** ✅ All services running

### NFS Ports Listening
```bash
LISTEN 0 4096 0.0.0.0:2049 0.0.0.0:*
LISTEN 0 4096 0.0.0.0:111 0.0.0.0:*
LISTEN 0 4096 [::]:2049 [::]:*
LISTEN 0 4096 [::]:111 [::]:*
```

**Status:** ✅ NFS ports listening on all interfaces

---

## Mount Attempt on UGREEN (Client)

### Command Executed
```bash
sudo mount -t nfs 192.168.40.40:/mnt/homelab-backups/lxc102-vzdump /mnt/homelab-backups
```

### Error Message
```
mount.nfs: access denied by server while mounting 192.168.40.40:/mnt/homelab-backups/lxc102-vzdump
```

**Status:** ❌ Mount fails every time with "access denied"

### Client Environment
- Mount point: `/mnt/homelab-backups` (created successfully)
- NFS client: Available on system
- Network connectivity: Working (SSH to 192.168.40.40 succeeds)

---

## Troubleshooting Performed

### ✅ What Worked

1. **Directory Creation & Permissions** - Successfully created with correct owner/permissions
2. **Export Rule Syntax** - Valid NFS export options, no syntax errors
3. **Firewall Configuration** - Rules added and verified
4. **NFS Server Services** - All running (nfs-server, rpc.mountd, nfsd, rpcbind)
5. **Port Listening** - Ports 111 and 2049 listening on all interfaces
6. **Export Registration** - exportfs -v shows the export with correct options
7. **Network Connectivity** - SSH between systems works fine

### ❌ What Failed

**Mount Attempt:** Every mount attempt fails with "access denied by server"
- Tried simple mount: FAILED
- Tried with sudo: FAILED
- Tried after firewall rule reload: FAILED
- Tried after NFS service restart: FAILED
- Tried after export re-registration: FAILED

---

## Diagnostic Data

### Export Options Currently Applied
```
sync        - Synchronous writes
wdelay      - Write delays (default, for performance)
hide        - Hide sub-exports
no_subtree_check  - Don't check subtree (required for modern NFS)
sec=sys     - System authentication (no Kerberos)
rw          - Read-write access
insecure    - Allow non-privileged source ports
no_root_squash    - Don't map root to anonymous
no_all_squash     - Don't map all users to anonymous
```

### What Was Tried

1. **Original options:** `rw,sync,no_subtree_check` → FAILED
2. **With fsid=0:** `rw,sync,fsid=0,no_root_squash` → FAILED
3. **With all_squash=no:** Invalid syntax, rejected by NFS
4. **With insecure:** `rw,sync,no_subtree_check,no_root_squash,insecure` → FAILED
5. **Current options:** `rw,sync,no_subtree_check,sec=sys,insecure,no_root_squash,no_all_squash` → FAILED

---

## Hypotheses

### Theory 1: NFSv4 vs NFSv3 Mismatch
- Export shows `sec=sys` (NFSv3 style)
- Proxmox might require NFSv4
- NFSv4 requires different authentication mechanism

### Theory 2: Proxmox Cluster-Specific Issue
- Both systems are Proxmox VE
- Proxmox may have additional layer of cluster authentication
- Standard NFS export might not work between Proxmox nodes

### Theory 3: Kerberos/Security Context Required
- Export shows `sec=sys` but Proxmox might require Kerberos
- NFSv4 typically uses `sec=krb5` or similar

### Theory 4: Firewall Still Blocking Something
- Rules installed but maybe not completely effective
- Proxmox firewall might need node-level rules, not just cluster-level

### Theory 5: rpcbind Registration Issue
- rpcbind running but maybe not properly registering NFS services
- exportfs shows the export but rpcbind might not see it

---

## Questions for Gemini

1. **Why does "access denied by server" occur when:**
   - The export is registered (exportfs -v shows it)
   - The firewall rules are in place
   - The NFS server and mountd are running
   - The ports are listening
   - Network connectivity is confirmed

2. **Is there a Proxmox-specific NFS configuration needed?**
   - Should we use NFSv4 instead of NFSv3?
   - Are there Proxmox cluster authentication requirements?
   - Do we need to configure NFS on the Proxmox cluster level (not just OS level)?

3. **What diagnostic command can pinpoint the exact rejection?**
   - Server-side logs to check?
   - Client-side verbose mount options?
   - NFS debug output?

4. **Are there known issues between Proxmox nodes sharing NFS?**
   - Should inter-node backups use different method?
   - Are there documented best practices for Proxmox-to-Proxmox NFS?

5. **What are the step-by-step correct options for:**
   - NFSv4 export from Proxmox
   - Client mount from another Proxmox node
   - Proper security context (sec=sys vs sec=krb5 vs others)

---

## Current State Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Directory created | ✅ | `/mnt/homelab-backups/lxc102-vzdump` exists |
| Permissions | ✅ | nobody:nogroup 755 |
| Export rule syntax | ✅ | Valid NFS options |
| Firewall rules | ✅ | Ports 111, 2049, 20048 open TCP/UDP |
| NFS server running | ✅ | nfs-server.service active |
| mountd running | ✅ | rpc.mountd.service active |
| nfsd running | ✅ | 8 kernel threads |
| Ports listening | ✅ | 111, 2049 on 0.0.0.0 and :: |
| Export registration | ✅ | Shows in exportfs -v with options |
| Client mount | ❌ | "access denied by server" |

---

## Alternative Approaches if NFS Can't Be Solved

1. **SSH-based rsync backups** - Already have working script, uses SSH tunnel instead of NFS
2. **UGREEN NAS only** - Daily rsync to `/storage/Media` (already working)
3. **Proxmox backup plugin** - Use Proxmox native clustering features
4. **Direct vzdump transfer via SSH** - Backup over SSH instead of NFS

---

## Files Available

- Server setup script: `/tmp/setup-homelab-nfs.sh`
- Firewall setup: `/tmp/homelab-firewall-nfs.sh`
- Diagnostics: `/tmp/diagnose-nfs.sh`
- NFS fixes attempted: `/tmp/fix-nfs-*.sh` (7 scripts)

All scripts are on Homelab at `/tmp/` if needed for testing.

---

**Request for Gemini:** Please analyze why this NFS mount is failing when all standard NFS components appear properly configured. Consider Proxmox-specific issues, NFSv4 requirements, and authentication mechanisms.
