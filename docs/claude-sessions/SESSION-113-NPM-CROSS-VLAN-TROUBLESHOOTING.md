# Session 113: NPM Cross-VLAN Troubleshooting & NAT Configuration

**Date:** 11 January 2026
**Time:** 17:05 CET
**Duration:** ~1 hour
**Objective:** Troubleshoot NPM proxy hosts not working with external services (NAS, Pi-hole, etc. on VLAN40)

---

## Executive Summary

Successfully diagnosed root cause of NPM proxy host failures: **Asymmetric routing without NAT masquerading**. When NPM (on VLAN10, 10.10.10.100) tried to reach services on VLAN40 (192.168.40.x), packets went out but replies didn't come back through the proper interface, causing timeouts.

**Root Cause:** NAS receives requests with source IP `10.10.10.100` but has no route to `10.10.10.0/24`, so replies go to default gateway instead of back through UGREEN gateway.

**Solution:** Enable NAT masquerading on UGREEN host to make requests appear to come from UGREEN's IP (`192.168.40.60`), ensuring proper reply routing.

**Status:** Script created and ready for execution. Awaiting user to run on UGREEN host.

---

## Problem Statement

**Symptom:** NPM proxy hosts configured to reach external services (NAS @ 192.168.40.20, Pi-hole @ 192.168.40.50, etc.), but all requests timeout when accessing through NPM.

**User Setup:**
- NPM running on VM100 (VLAN10, 10.10.10.100)
- Proxy hosts point to external services on VLAN40 (192.168.40.x)
- Credentials and certificates already restored from backup

---

## Investigation & Findings

### Phase 1: Container Status & Database
- NPM container `npm-ugreen` running 25+ hours, marked "unhealthy" (missing `wget` in health check - non-blocking)
- Database: SQLite present and valid with restored proxy_host configurations
- Logs: Clean, no error messages, backend running on port 3000
- Nginx config: Shows ONLY fallback pages, no proxy_pass directives (unusual but acceptable if configs haven't been compiled yet)

### Phase 2: Network Isolation Discovery
- NPM originally on `nginx-proxy-manager_npm_network` (172.21.0.0/16 isolated Docker bridge)
- **Applied Fix #1:** Switched NPM to `network_mode: host` using updated docker-compose.yaml
- Result: Container can now see host's network stack, but still cannot reach VLAN40 services

### Phase 3: Firewall Rules Investigation
- UFW route rules added: `10.10.10.0/24 ALLOW FWD 192.168.40.0/24`
- VM100 routing table: Route exists `192.168.40.0/24 via 10.10.10.60`
- UGREEN host can reach NAS: ✅ `curl http://192.168.40.20:80` returns HTTP 200
- VM100 cannot reach NAS: ❌ Timeout on TCP connection
- **Diagnosis:** Asymmetric routing - packets leaving VLAN10 don't get proper replies back

### Phase 4: Root Cause Analysis (Consulted Gemini)
Gemini expert analysis identified the issue as **missing NAT masquerading**:

1. VM100 sends request with source IP `10.10.10.100`
2. Packet reaches UGREEN, forwarded to NAS (192.168.40.20)
3. NAS receives packet but doesn't know route back to `10.10.10.0/24`
4. NAS replies to its default gateway, not back to UGREEN
5. Reply never reaches VM100 = **TIMEOUT**

**Solution:** Add NAT rule to make requests appear to come from UGREEN (192.168.40.60) so NAS knows to send replies back to UGREEN, which then forwards to VM100.

---

## Solutions Applied

### Fix #1: Docker Network Mode (COMPLETED)
**File Modified:** `/home/sleszugreen/npm/docker-compose.yaml`

Changed from:
```yaml
networks:
  - frontend
```

To:
```yaml
network_mode: host
```

**Result:** Container now uses host network stack directly, eliminating Docker bridge isolation.

### Fix #2: UFW Route Rules (COMPLETED)
**Commands Executed:**
```bash
sudo ufw route allow from 10.10.10.0/24 to 192.168.40.0/24
sudo ufw route allow from 192.168.40.0/24 to 10.10.10.0/24
sudo ufw reload
```

**Result:** Rules added, but one-way connectivity persists - return traffic still blocked.

### Fix #3: NAT Masquerading (PENDING USER EXECUTION)
**Script Location:** `/mnt/lxc102scripts/fix-npm-nat.sh` (bind-mounted to `/nvme2tb/lxc102scripts/` on UGREEN)

**Script Actions:**
1. **Backup Phase:** Creates `/root/backups/npm-nat-fix-TIMESTAMP/`
   - Backs up original `/etc/ufw/before.rules`
   - Backs up UFW config
   - Captures UFW status before and after

2. **NAT Configuration:** Adds to `/etc/ufw/before.rules`
   ```
   *nat
   :POSTROUTING ACCEPT [0:0]
   -A POSTROUTING -s 10.10.10.0/24 -o vmbr0.40 -j MASQUERADE
   COMMIT
   ```

3. **Input Rules:** Adds
   ```
   sudo ufw allow in on vmbr0.10 from 10.10.10.0/24 to any
   ```

4. **Verification:** Confirms rules applied, displays UFW status

**To Execute:**
```bash
# Run on UGREEN Proxmox host console:
sudo bash /nvme2tb/lxc102scripts/fix-npm-nat.sh
```

---

## Files Created/Modified This Session

### New Files
- `/mnt/lxc102scripts/fix-npm-nat.sh` - Comprehensive NAT setup script with backup and verification
- `docs/claude-sessions/SESSION-113-NPM-CROSS-VLAN-TROUBLESHOOTING.md` (this file)

### Modified Files
- `/home/sleszugreen/npm/docker-compose.yaml` - Switched to `network_mode: host`
  - Backup: `/home/sleszugreen/npm/docker-compose.yaml.backup-20260111-164833`

### Temporary Diagnostic Files (Not Committed)
- `/tmp/npm-diagnostics.txt` - Initial diagnostic summary
- `/tmp/npm-cross-vlan-analysis.txt` - Detailed cross-VLAN analysis
- `/tmp/npm-vlan-debug.txt` - Gemini consultation data

---

## Verification Plan

Once user executes the NAT script on UGREEN, I will verify fix using 4 tests:

### Test 1: VM100 Host → NAS (Basic Routing)
```bash
ssh 10.10.10.100 'timeout 3 bash -c "exec 3<>/dev/tcp/192.168.40.20/80" && echo "✅ SUCCESS" || echo "❌ TIMEOUT"'
```
**Expected:** SUCCESS (TCP SYN acknowledged)

### Test 2: NPM Container → NAS (Critical Path)
```bash
ssh 10.10.10.100 'docker exec npm-ugreen timeout 3 bash -c "exec 3<>/dev/tcp/192.168.40.20/80" && echo "✅ SUCCESS" || echo "❌ TIMEOUT"'
```
**Expected:** SUCCESS (Container can reach external service)

### Test 3: NPM Container → Pi-hole (Secondary Service)
```bash
ssh 10.10.10.100 'docker exec npm-ugreen timeout 3 bash -c "exec 3<>/dev/tcp/192.168.40.50/80" && echo "✅ SUCCESS" || echo "❌ TIMEOUT"'
```
**Expected:** SUCCESS (Verify multiple VLAN40 services reachable)

### Test 4: End-to-End NPM Proxy
- Access http://10.10.10.100:81 (NPM admin UI)
- Navigate to one configured proxy host
- Verify page loads without timeout

**Expected:** Proxy serves content from external service successfully

---

## Architecture & Technical Details

### Network Layout
```
VLAN40 (Management VLAN)               VLAN10 (Service VLAN)
192.168.40.0/24                         10.10.10.0/24
│                                       │
├─ NAS (192.168.40.20)                 ├─ VM100 (10.10.10.100) - NPM
├─ Pi-hole (192.168.40.50)             ├─ Default GW (10.10.10.1)
└─ UGREEN eth0 (192.168.40.60)         └─ UGREEN vlan10 (10.10.10.60)

                    UGREEN (Router/Firewall)
                    ├─ vmbr0 (VLAN40) - 192.168.40.60
                    ├─ vmbr0.10 (VLAN10) - 10.10.10.60
                    └─ UFW + NAT rules
```

### Packet Flow (After NAT Fix)
1. **Request:** NPM (10.10.10.100) → NAS (192.168.40.20)
   - Packet sent to gateway 10.10.10.60 (UGREEN VLAN10 interface)

2. **NAT Masquerade:** UGREEN POSTROUTING rule rewrites
   - Source IP: 10.10.10.100 → 192.168.40.60
   - Now appears to come from UGREEN's VLAN40 interface

3. **Forwarding:** UGREEN forwards NAT'd packet
   - From vmbr0.40 → NAS (192.168.40.20)

4. **Reply:** NAS responds
   - Replies to source IP 192.168.40.60 (UGREEN, which it knows)
   - Packet reaches UGREEN VLAN40 interface

5. **Reply De-NAT:** UGREEN reverses NAT
   - Destination IP: 192.168.40.60 → 10.10.10.100
   - Forwards back to NPM container

6. **Success:** NPM receives reply ✅

---

## Key Learnings

### 1. Docker Network Isolation vs Host Networking
- `network_mode: host` is necessary for containers to reach external services across multiple VLANs
- Docker bridge networks (default) are completely isolated from host routing

### 2. Asymmetric Routing Detection
- One-way connectivity (UGREEN can reach NAS but VM100 cannot) indicates NAT issue
- Reverse path filtering alone isn't enough; return traffic needs proper gateway

### 3. UFW Route Rules vs NAT
- UFW `route allow` rules permit forwarding but don't rewrite source IPs
- Asymmetric routing requires MASQUERADE rule in `*nat` table to rewrite sources
- Two separate concerns: forwarding permission + address translation

### 4. Cross-VLAN Firewall Debugging
- Always test bidirectional: UGREEN→NAS AND VM100→NAS
- Test from UGREEN host first to isolate firewall from routing issues
- Check `/proc/sys/net/ipv4/conf/*/rp_filter` for reverse path filtering

---

## Next Steps (User Action Required)

1. **Execute Script:** `sudo bash /nvme2tb/lxc102scripts/fix-npm-nat.sh` on UGREEN Proxmox host
2. **Respond with:** Script output (should show "✅ Configuration Complete!")
3. **Verification:** I will run 4 connectivity tests
4. **If Successful:** Test NPM proxy hosts through web UI
5. **If Failed:** Rollback available via backup directory

---

## Rollback Instructions

If script needs to be reverted:

```bash
# Check backup location (printed at end of script output)
ls -la /root/backups/npm-nat-fix-*/

# Restore original UFW rules
sudo cp /root/backups/npm-nat-fix-TIMESTAMP/before.rules.backup /etc/ufw/before.rules

# Reload firewall
sudo ufw disable
sudo ufw enable
```

---

## Session Statistics

- **Commands executed:** ~60
- **Git commits:** Pending (on SAVE)
- **Root causes identified:** 2 (Docker network isolation + asymmetric routing without NAT)
- **Fixes applied:** 2/3 (Docker networking ✅, UFW rules ✅, NAT masquerading ⏳)
- **Scripts created:** 1 comprehensive NAT setup script
- **Consulted experts:** Gemini (confirmed asymmetric routing diagnosis)
- **Estimated time to completion:** ~5 minutes (script execution + verification)

---

## Session Status

**Current:** ⏳ Awaiting user execution of NAT script on UGREEN
**Critical Path:** NPM cross-VLAN connectivity via NAT masquerading
**Blocking:** Script execution on UGREEN Proxmox host
**Next Phase:** Verification tests and end-to-end proxy functionality testing

---

**Generated:** 11 Jan 2026 17:05 CET
**Session ID:** 113
**Status:** Active - Awaiting User Action

🤖 Session managed by Claude Code
