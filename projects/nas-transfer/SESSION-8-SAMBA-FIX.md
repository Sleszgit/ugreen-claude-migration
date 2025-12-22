# Session 8: Samba Windows Access - Firewall Issue Resolution

**Date:** 2025-12-20
**Status:** ✅ COMPLETE - Samba Windows Access Working
**Outcome:** SMB share now fully accessible from Windows desktop

---

## Problem Statement

Windows computer (192.168.99.6) on separate subnet could not connect to Samba share on Proxmox (192.168.40.60):
- Attempted mapping: `net use Z: \\192.168.40.60\ugreen20tb`
- Result: Connection hung indefinitely
- `Test-NetConnection` on port 445 showed: `TcpTestSucceeded: False`

**Critical Observation:** Synology NAS on same Proxmox subnet (192.168.40.10) worked fine from Windows, proving:
- ✅ Network connectivity between subnets exists
- ✅ Port 445 is NOT blocked by UDM Pro
- ✅ Issue is specific to Proxmox/Samba, not network firewall

---

## Root Cause Analysis

**Diagnosis Process:**

1. **Verified Samba Configuration:** ✅
   ```bash
   testparm -v /etc/samba/smb.conf
   # Result: Config valid, share configured correctly
   ```

2. **Verified Samba Service:** ✅
   ```bash
   systemctl status smbd
   # Result: Active and running
   ```

3. **Verified Port Listening:** ✅
   ```bash
   ss -tlnp | grep smbd
   # Result: Listening on 0.0.0.0:445 and [::]:445
   ```

4. **Tested SMB Connectivity:** ✅ (locally)
   ```bash
   smbclient -L localhost -U sleszugreen
   # Result: Share visible and accessible locally
   ```

5. **Network Test from Windows:** ❌ (port 445 blocked)
   ```powershell
   Test-NetConnection -ComputerName 192.168.40.10 -Port 445
   # Result: Synology - TcpTestSucceeded: True ✅
   Test-NetConnection -ComputerName 192.168.40.60 -Port 445
   # Result: Proxmox - TcpTestSucceeded: False ❌
   ```

6. **Checked Proxmox Firewall:** ❌ (FOUND THE ISSUE)
   ```bash
   sudo iptables -L -n | grep 445
   # Result: Multiple DROP rules for port 445
   DROP tcp --  0.0.0.0/0  0.0.0.0/0  multiport dports 135,139,445
   ```

**Root Cause:** Proxmox firewall's default security policy blocks SMB ports (445, 139) by default to prevent ransomware/worm propagation.

---

## Solution Implemented

### Step 1: Identify Correct Firewall Service

Found multiple firewall services on Proxmox:
- `firewalld.service` (not installed)
- `proxmox-firewall.service` (modern nftables)
- `pve-firewall.service` (classic iptables) ← Used for config in `/etc/pve/firewall/`
- `pvefw-logger.service` (logging)

**Lesson:** Always verify service names with `systemctl list-units --all | grep -i firewall`

### Step 2: Add Firewall Rules

Edited `/etc/pve/firewall/cluster.fw`:

```bash
sudo nano /etc/pve/firewall/cluster.fw
```

Added rules to allow SMB from Windows desktop ONLY (principle of least privilege):

```
# Allow SMB (Samba) from Windows desktop for NAS access
IN ACCEPT -source 192.168.99.6 -p tcp -dport 445 -log nolog
IN ACCEPT -source 192.168.99.6 -p tcp -dport 139 -log nolog
```

### Step 3: Restart Firewall Service

```bash
sudo systemctl restart pve-firewall.service
```

### Step 4: Verify Rules Applied

```bash
sudo iptables -L -n | grep 445
```

Output showed new ACCEPT rules:
```
RETURN     tcp  --  192.168.99.6  0.0.0.0/0  tcp dpt:445
```

### Step 5: Test from Windows

```powershell
Test-NetConnection -ComputerName 192.168.40.60 -Port 445 -InformationLevel Detailed
# Result: TcpTestSucceeded : True ✅
```

### Step 6: Verify SMB Share Visibility

```cmd
net view \\192.168.40.60
# Result: Share "ugreen20tb" visible ✅
```

### Step 7: Map Network Drive

```cmd
net use Z: \\192.168.40.60\ugreen20tb /user:sleszugreen /persistent:yes
# Result: Network drive mapped successfully ✅
```

---

## Configuration Details

**Proxmox Firewall File:** `/etc/pve/firewall/cluster.fw`

**Policy:**
- `policy_in: DROP` - Default: reject all incoming traffic
- `policy_out: ACCEPT` - Allow all outgoing traffic
- Exception rules allow specific ports/sources

**Full Current Rules:**
```
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT
log_level_in: info

[RULES]
# Allow SSH from trusted desktop
IN ACCEPT -source 192.168.99.6 -p tcp -dport 22 -log nolog
IN ACCEPT -source 192.168.99.6 -p tcp -dport 22022 -log nolog

# Allow Proxmox Web UI from trusted desktop
IN ACCEPT -source 192.168.99.6 -p tcp -dport 8006 -log nolog

# Allow SMB (Samba) from Windows desktop for NAS access
IN ACCEPT -source 192.168.99.6 -p tcp -dport 445 -log nolog
IN ACCEPT -source 192.168.99.6 -p tcp -dport 139 -log nolog

# Allow ICMP (ping) for network diagnostics
IN ACCEPT -p icmp -log nolog

# Allow localhost communication
IN ACCEPT -source 127.0.0.1 -log nolog
IN ACCEPT -source ::1 -log nolog

# Allow established and related connections
IN ACCEPT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog
IN ACCEPT -p udp -m conntrack --ctstate ESTABLISHED,RELATED -log nolog

# Drop everything else and log it
IN DROP -log warning
```

---

## Security Considerations

✅ **Best Practices Applied:**
1. **IP-Specific Rules:** Only allow SMB from Windows desktop IP (192.168.99.6), not entire subnet
2. **Port-Specific:** Only ports 445 and 139 (SMB), not other services
3. **Logging:** Keep logging enabled (`-log nolog` prevents log spam while maintaining audit trail)
4. **Default Deny:** Proxmox default DROP policy prevents accidental exposure
5. **Connection State:** ESTABLISHED,RELATED connections allowed for return traffic

⚠️ **Security Notes:**
- SMB ports are commonly targeted by ransomware
- Restricting to single IP is essential for multi-subnet setup
- Consider additional protections:
  - Keep Samba updated
  - Monitor SMB access logs
  - Consider VPN for remote access
  - Use strong Samba passwords

---

## Lessons Learned

### What Worked Well
1. **Systematic Diagnostics:** Testing each component (service, ports, connectivity, firewall) isolated the issue
2. **Comparison Method:** Testing Synology (working) vs Proxmox (failing) revealed the firewall was the culprit
3. **Security by Default:** Proxmox's default DROP policy protected against SMB-based attacks

### What Could Be Improved
1. **Documentation:** Proxmox firewall service naming is confusing (pve-firewall vs proxmox-firewall vs pvefw)
2. **Error Messages:** Windows hang gave no indication of firewall block vs service issue
3. **Initial Setup:** Samba setup script didn't mention Proxmox firewall requirement

### Key Takeaways
- **Always test baseline connectivity** (ping, TCP port) before assuming application issue
- **Firewall logging is critical** - check both directions (external firewall + host firewall)
- **Proxmox has default restrictive security** - document firewall rules needed for services
- **Service naming matters** - verify with `systemctl` commands, don't guess

---

## Current Status

**✅ Samba Windows Access: COMPLETE**

| Component | Status | Details |
|-----------|--------|---------|
| Samba Service | ✅ Running | smbd active, ports 445/139 listening |
| Configuration | ✅ Valid | testparm validation passed |
| Proxmox Firewall | ✅ Configured | Rules added for SMB access |
| Windows Connectivity | ✅ Working | Port 445 reachable, SMB share visible |
| Network Drive | ✅ Mapped | Z: drive accessible in Explorer & Total Commander |
| Data Access | ✅ Working | 5.7 TB media content accessible |

---

## Next Steps

### Immediate
1. ✅ Windows can now browse UGREEN storage directly
2. ✅ Can manage media files from Windows desktop
3. ✅ Ready for additional file transfers

### Optional Future
1. Consider SFTP as additional access method (encrypted, more secure)
2. Set up automated backups from Windows to UGREEN
3. Monitor SMB access logs for security
4. Document similar rules for other services (if added)

---

## Files Modified

1. `/etc/pve/firewall/cluster.fw` - Added SMB firewall rules
2. `/home/sleszugreen/.claude/CLAUDE.md` - Documented Samba setup and firewall config
3. `/home/sleszugreen/hardware/README.md` - Added Windows access details to UGREEN specs

---

## References & Resources

**Proxmox Firewall Documentation:**
- Config file: `/etc/pve/firewall/cluster.fw`
- Service: `pve-firewall.service` (iptables-based)
- Modern alternative: `proxmox-firewall.service` (nftables-based)

**Samba/SMB:**
- Ports: 445 (SMB direct), 139 (NetBIOS legacy)
- Config: `/etc/samba/smb.conf`
- Service: `smbd` (file sharing), `nmbd` (NetBIOS)
- Validation: `testparm -v /etc/samba/smb.conf`
- Client: `smbclient` (test connectivity)

**Windows SMB Access:**
- Share visibility: `net view \\SERVER`
- Map drive: `net use DRIVE: \\SERVER\share /user:USERNAME /persistent:yes`
- Test port: `Test-NetConnection -ComputerName IP -Port 445 -InformationLevel Detailed`

---

**Session Duration:** ~1 hour
**Difficulty:** Medium (firewall debugging)
**Success Rate:** 100%

**Last Updated:** 2025-12-20 (Session 8)
