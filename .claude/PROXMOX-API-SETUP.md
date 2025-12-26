# Proxmox API Access Setup & Troubleshooting

**Status:** ✅ Properly configured and tested (25 Dec 2025)

---

## Overview

**Why API instead of SSH?**
- ✅ Zero risk of accidental modifications (read-only enforced at Proxmox level)
- ✅ Tokens can be revoked instantly
- ✅ All API calls are logged by Proxmox
- ✅ Better than SSH: Safer, more auditable, no shell access
- ✅ Separate tokens per purpose (cluster vs specific VM)
- ✅ Works from container to host with proper firewall setup

---

## Token Configuration (Already Set Up)

### Token 1: Cluster-Wide Reader
```
Token File:        ~/.proxmox-api-token (gitignored, mode 600)
Token ID:          claude-reader@pam!claude-token
User:              claude-reader@pam
Role:              PVEAuditor (read-only cluster access)
Permissions:       Query all containers, VMs, nodes, status, logs
Restrictions:      NO write/modify/delete operations
```

### Token 2: VM 100 Reader
```
Token File:        ~/.proxmox-vm100-token (gitignored, mode 600)
Token ID:          vm100-reader@pam!vm100-token
User:              vm100-reader@pam
Role:              PVEAuditor (read-only cluster access)
Permissions:       Query VM 100 status, logs, resources
Restrictions:      NO write/modify/delete operations
```

---

## CRITICAL: Firewall Configuration

### ⚠️ LESSON LEARNED (25 Dec 2025)

**DON'T use `/etc/pve/firewall/cluster.fw` for container↔host API access**

Problem:
- Proxmox firewall config creates RETURN rules in custom chains
- Result: Configuration looks correct but traffic is still blocked
- This is a known limitation of Proxmox firewall configuration

**Solution: Use direct iptables rules instead**

### Correct Setup (Permanent)

**ON PROXMOX HOST, run ONCE:**
```bash
sudo iptables -I INPUT 1 -s 192.168.40.82 -p tcp --dport 8006 -j ACCEPT
```

This creates:
```
ACCEPT     tcp  --  192.168.40.82        0.0.0.0/0            tcp dpt:8006
```

**Make Persistent (Option 1 - Recommended):**

Add to `/etc/pve/firewall/cluster.fw` **BELOW other rules** for override:
```
IN ACCEPT -source 192.168.40.82 -p tcp -dport 8006
```

Then restart firewall:
```bash
sudo systemctl restart pve-firewall.service
```

**Make Persistent (Option 2 - Alternative):**

If iptables-save available:
```bash
sudo iptables-save > /etc/iptables/rules.v4
```

### Verify Setup

**From container:**
```bash
bash /mnt/lxc102scripts/test-api-from-container.sh
```

Should show: `✅ API call succeeded!` and return Proxmox version

**Or manually test:**
```bash
# From container:
PROXMOX_TOKEN=$(cat ~/.proxmox-api-token)
curl -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$PROXMOX_TOKEN" \
  https://192.168.40.60:8006/api2/json/cluster/status
```

---

## API Usage Examples

### Query Cluster Status
```bash
PROXMOX_TOKEN=$(cat ~/.proxmox-api-token)
curl -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$PROXMOX_TOKEN" \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/status
```

### Query All Containers
```bash
PROXMOX_TOKEN=$(cat ~/.proxmox-api-token)
curl -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$PROXMOX_TOKEN" \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/lxc
```

### Query All VMs
```bash
PROXMOX_TOKEN=$(cat ~/.proxmox-api-token)
curl -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$PROXMOX_TOKEN" \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/qemu
```

### Query VM 100 Status
```bash
VM100_TOKEN=$(cat ~/.proxmox-vm100-token)
curl -k -H "Authorization: PVEAPIToken=vm100-reader@pam!vm100-token=$VM100_TOKEN" \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/qemu/100/status/current
```

### Query Container 102 Status
```bash
PROXMOX_TOKEN=$(cat ~/.proxmox-api-token)
curl -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$PROXMOX_TOKEN" \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/lxc/102/status/current
```

---

## Creating New Tokens (If Needed)

**⚠️ ONLY do this if existing tokens are lost/compromised**

### Create Cluster-Wide Token
```bash
# On Proxmox host:
sudo pveum user add claude-reader@pam
sudo pveum acl modify / -user claude-reader@pam -role PVEAuditor
sudo pveum user token add claude-reader@pam claude-token --expire 0 --output-format json
```

Output will include the token value - **save it immediately** (only shown once).

Save to file:
```bash
# From the output, extract the token value and save:
echo "TOKEN_VALUE_HERE" > ~/.proxmox-api-token
chmod 600 ~/.proxmox-api-token
```

### Create VM 100-Specific Token
```bash
# On Proxmox host:
sudo pveum user add vm100-reader@pam
sudo pveum acl modify /nodes/ugreen/qemu/100 -user vm100-reader@pam -role PVEAuditor
sudo pveum user token add vm100-reader@pam vm100-token --expire 0 --output-format json
```

Save token to `~/.proxmox-vm100-token`:
```bash
echo "TOKEN_VALUE_HERE" > ~/.proxmox-vm100-token
chmod 600 ~/.proxmox-vm100-token
```

---

## Troubleshooting API Access

### Issue: Connection Refused

**Symptoms:** `Connection refused` when running curl commands

**Checklist:**
1. Check container can reach host:
   ```bash
   ping 192.168.40.60
   ```

2. Check port 8006 is open on Proxmox host:
   ```bash
   sudo ss -tlnp | grep 8006
   ```

3. Check iptables rule exists:
   ```bash
   sudo iptables -L -n | grep 8006
   ```

4. Verify token file exists:
   ```bash
   ls -la ~/.proxmox-api-token
   cat ~/.proxmox-api-token
   ```

5. Test directly from Proxmox host:
   ```bash
   curl -k https://localhost:8006/api2/json/version
   ```

### Issue: Permission Denied

**Symptoms:** `401 Unauthorized` response

**Checklist:**
1. Verify token value is correct:
   ```bash
   cat ~/.proxmox-api-token
   ```

2. Check user exists and has PVEAuditor role:
   ```bash
   sudo pveum user list | grep claude-reader
   sudo pveum acl list / | grep claude-reader
   ```

3. Verify token hasn't been revoked:
   ```bash
   sudo pveum user token list claude-reader@pam
   ```

### Issue: Token Command Not Recognized

**Symptoms:** `pveum: no command specified`

**Solution:** Update pveum command syntax (Proxmox version dependent)

Check Proxmox version:
```bash
pveversion
```

Reference: https://pve.proxmox.com/wiki/User_Management

---

## Security Best Practices

**Token File Protection:**
```bash
# File should be owned by user and mode 600:
ls -la ~/.proxmox-api-token
# Should show: -rw------- 1 sleszugreen sleszugreen

# Fix permissions if needed:
chmod 600 ~/.proxmox-api-token
```

**Never:**
- ❌ Share token values in chat or logs
- ❌ Commit token files to git (use .gitignore)
- ❌ Store tokens in plain text in scripts
- ❌ Use tokens in command history

**If token compromised:**
```bash
# On Proxmox host - revoke immediately:
sudo pveum user token delete claude-reader@pam claude-token

# Then create new token (see "Creating New Tokens" section above)
```

---

## API Documentation

- [Proxmox VE API Documentation](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [User Management Guide](https://pve.proxmox.com/wiki/User_Management)
- [pveum Manual](https://pve.proxmox.com/pve-docs/pveum.1.html)

---

## See Also

- `INFRASTRUCTURE.md` - Network and firewall overview
- `PROXMOX-COMMANDS.md` - Command reference (pveum section)
- `PATHS-AND-CONFIG.md` - File locations and configuration
