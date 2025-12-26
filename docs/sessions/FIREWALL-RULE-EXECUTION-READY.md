# Proxmox API Firewall Rule - Ready to Execute

**Status:** Prepared and ready to execute (waiting for Seriale 2023 transfer to complete)

**Date Prepared:** 26 Dec 2025
**Transfer Status:** In progress (237GB of data)

---

## What This Does

Adds a firewall rule to allow LXC 102 (192.168.40.82) to access Proxmox API (port 8006) on the UGREEN Proxmox host (192.168.40.60).

---

## Current Situation

- ✅ LXC 102 can reach Proxmox host (ping works)
- ✅ API token exists (`~/.proxmox-api-token`)
- ❌ Port 8006 is blocked by firewall
- ⏳ Seriale 2023 transfer in progress via screen session

---

## Execution Steps (Run on Proxmox Host Once Transfer Completes)

### Step 1: Connect to Proxmox Host
Use your preferred method (SSH, web console, etc.)

### Step 2: Add Firewall Rule

```bash
cat >> /etc/pve/firewall/cluster.fw << 'EOF'

# Allow LXC 102 to access Proxmox API
IN ACCEPT -source 192.168.40.82 -p tcp -dport 8006 -log nolog
EOF
```

### Step 3: Verify Rule Was Added

```bash
tail -5 /etc/pve/firewall/cluster.fw
```

Expected output should show the new rule with the comment "Allow LXC 102 to access Proxmox API"

### Step 4: Restart Firewall Service

```bash
systemctl restart pve-firewall.service
```

This should complete quickly (usually < 5 seconds) and shouldn't affect established connections.

---

## Testing After Restart (from LXC 102)

Once firewall rules are applied and service restarted, test with:

```bash
bash ~/test_api.sh
```

Expected output:
- Version endpoint should return JSON with version info
- Nodes endpoint should return cluster node information

---

## Prepared Files

- **Test script:** `~/test_api.sh` ✅ Ready
- **API token:** `~/.proxmox-api-token` ✅ Ready
- **LXC 102 IP:** 192.168.40.82 ✅ Confirmed

---

## Notes

- The firewall restart is safe - it won't affect the existing Seriale 2023 transfer (established connections persist)
- If you need to rollback, remove the lines from `/etc/pve/firewall/cluster.fw` and restart
- The rule is added to cluster-wide firewall config, so it persists across reboots

---

**Next Steps:** Monitor transfer completion, then execute the steps above.
