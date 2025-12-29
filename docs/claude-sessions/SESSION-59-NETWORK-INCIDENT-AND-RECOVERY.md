# SESSION 59: Network Incident & Recovery - Critical Lessons Learned

**Date:** 29 Dec 2025  
**Status:** 🟢 RECOVERED - INCIDENT CLOSED  
**Location:** UGREEN Proxmox Host & LXC 102  
**Device:** UGREEN DXP4800+ (192.168.40.60)  
**Severity:** CRITICAL - Full network loss, required console recovery

---

## 📋 Incident Summary

**What Happened:**
- SESSION 58 VLAN 10 reconfiguration script was executed on UGREEN Proxmox host
- Script used unsafe network restart method
- Network configuration became broken, all interfaces went down
- Complete loss of remote SSH access (required physical console)
- UGREEN Proxmox host was unreachable for ~2 hours

**Root Cause:** Claude Code instance (browser-based) made critical safety mistakes:
1. Used `systemctl restart networking` on remote host (EXTREMELY DANGEROUS)
2. Didn't implement auto-rollback timer
3. Didn't verify prerequisites (VLAN 10 on UniFi switch)
4. Used unsafe backup file naming (colons in timestamps)
5. Used heredoc syntax that's fragile on remote systems
6. Left VM 100 pointing to non-existent vmbr0.10 bridge

---

## 🔴 What Broke

### Network Interfaces Configuration
- `/etc/network/interfaces` file was completely missing/corrupted after failed recovery attempt
- vmbr0 bridge was non-functional
- LXC 102 container couldn't start (bridge didn't exist)
- All remote access lost

### VM 100 Orphaned
- Network config pointed to `vmbr0.10` (VLAN 10 bridge)
- vmbr0.10 was never successfully created
- VM 100 couldn't get network access even if bridge existed

---

## ✅ Recovery Steps Executed

### Step 1: Physical Console Access
- User connected via KVM (GLI.net console device)
- Could see filesystem mount errors and boot failures

### Step 2: Manual Network File Recovery
Used this command to recreate `/etc/network/interfaces`:

```bash
sudo printf 'auto lo\niface lo inet loopback\n\niface nic0 inet manual\n\nauto vmbr0\niface vmbr0 inet static\n    address 192.168.40.60/24\n    gateway 192.168.40.1\n    bridge-ports nic1\n    bridge-stp off\n    bridge-fd 0\n\niface nic1 inet manual\n\nsource /etc/network/interfaces.d/*\n' | sudo tee /etc/network/interfaces
```

Then applied safely:
```bash
sudo ifreload -a
```

Verified:
```bash
ip addr show vmbr0
ping -c 2 192.168.40.1
```

### Step 3: VM 100 Network Restoration
Restored original network configuration:
```bash
sudo qm set 100 --net0 virtio=BC:24:11:8B:FD:EC,bridge=vmbr0,firewall=1
sudo qm start 100
```

Verified:
```bash
sudo qm status 100  # Returns: status: running
ping -c 2 192.168.40.102
```

---

## 🟢 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| vmbr0 | ✅ UP | 192.168.40.60/24, operational |
| Gateway | ✅ REACHABLE | 192.168.40.1, responding |
| LXC 102 | ✅ RUNNING | Can start/stop, networked |
| VM 100 | ✅ RUNNING | Restored to vmbr0, IP: 192.168.40.102 |
| Network Config | ✅ STABLE | `/etc/network/interfaces` correct |

---

## 🚨 CRITICAL LESSONS LEARNED

### NEVER DO THIS (DANGEROUS)
```bash
systemctl restart networking              # ❌ DANGEROUS on remote host
/etc/init.d/networking restart            # ❌ DANGEROUS on remote host
echo "config" > /etc/network/interfaces    # ❌ Doesn't preserve permissions
heredoc > /etc/network/interfaces          # ❌ Can fail on some shells
```

### DO THIS INSTEAD (SAFE)
```bash
# Method 1: Safe with backup and rollback timer
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp /etc/network/interfaces /etc/network/interfaces.backup_${TIMESTAMP}
(sleep 120 && cp /etc/network/interfaces.backup_${TIMESTAMP} /etc/network/interfaces && ifreload -a) &
TIMER_PID=$!

# Make your changes with printf | tee (not echo or heredoc)
printf 'your\nconfig\nhere\n' | sudo tee /etc/network/interfaces

# Apply with ifreload (not systemctl)
sudo ifreload -a

# Test and kill timer
ping -c 3 192.168.40.1 && kill $TIMER_PID
```

### Safe Filename Convention
```bash
# BAD - colons cause shell parsing issues
backup.20251229-06:35:49

# GOOD - underscores are safe
backup_20251229_063549
```

### Safe File Creation Pattern
```bash
# BAD - uses heredoc which can fail
cat > /etc/network/interfaces << 'EOF'
config here
EOF

# GOOD - uses printf | tee which is always reliable
printf 'config\nhere\n' | sudo tee /etc/network/interfaces
```

---

## 📋 Complete Safe Network Reconfiguration Template

```bash
#!/bin/bash
# Safe remote network configuration with auto-rollback

set -e

# Step 1: Create backup with safe filename (underscores, not colons)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP="/etc/network/interfaces.backup_${TIMESTAMP}"
echo "[1] Backing up network config..."
sudo cp /etc/network/interfaces "$BACKUP"

# Step 2: Verify backup is readable
echo "[2] Verifying backup..."
sudo cat "$BACKUP" > /dev/null || exit 1

# Step 3: Start 120-second auto-rollback timer
echo "[3] Starting auto-rollback timer (120 seconds)..."
(sleep 120 && echo "[TIMER] Restoring backup..." && \
 sudo cp "$BACKUP" /etc/network/interfaces && \
 sudo ifreload -a && \
 echo "[TIMER] AUTO-ROLLBACK EXECUTED") &
TIMER_PID=$!

# Step 4: Create new configuration (using printf | tee, NOT heredoc)
echo "[4] Writing new network configuration..."
sudo printf 'auto lo\niface lo inet loopback\n\nauto vmbr0\niface vmbr0 inet static\n    address 192.168.40.60/24\n    gateway 192.168.40.1\n    bridge-ports nic1\n    bridge-stp off\n    bridge-fd 0\n\niface nic1 inet manual\n' | sudo tee /etc/network/interfaces

# Step 5: Apply changes with ifreload (NOT systemctl restart)
echo "[5] Applying configuration with ifreload -a..."
sudo ifreload -a

# Step 6: Test connectivity
echo "[6] Testing connectivity..."
if ping -c 3 192.168.40.1 > /dev/null 2>&1; then
    echo "[SUCCESS] Network is UP - killing auto-rollback timer"
    kill $TIMER_PID
    wait $TIMER_PID 2>/dev/null || true
    echo "✓ Network reconfiguration completed successfully"
    exit 0
else
    echo "[FAILED] Network is DOWN - waiting for auto-rollback..."
    wait $TIMER_PID
    echo "✗ Auto-rollback was executed, restored previous config"
    exit 1
fi
```

---

## 🛑 PREVENTION FOR FUTURE NETWORK CHANGES

### Pre-Check Checklist (DO THIS FIRST)
- [ ] Is this VLAN configured on UniFi switch?
- [ ] Is the switch port trunked for this VLAN?
- [ ] Can I ping the VLAN gateway from another device?
- [ ] Do I have physical console access as backup?
- [ ] Have I created a safe backup with underscores in filename?
- [ ] Is the auto-rollback timer script written and tested?

### Safe Methods (In Order of Preference)
1. **✅ BEST:** Use Proxmox Web UI (built-in safety)
2. **✅ GOOD:** Use `pvesh` API commands (CLI but safer)
3. **✅ OKAY:** Edit `/etc/network/interfaces` with auto-rollback timer + ifreload
4. **❌ AVOID:** Direct file editing without safeguards
5. **❌ NEVER:** Use `systemctl restart networking` remotely

### Commands Reference
```bash
# Proxmox API method (safest)
sudo pvesh create /nodes/ugreen/network -type bridge -iface vmbr0.10

# Safe Debian method (with safeguards)
ifreload -a                                # Reload single interface safely
ifreload vmbr0                            # Reload specific interface
ifreload -a                               # Reload all (safer than restart)

# DANGEROUS - Never use these remotely
systemctl restart networking              # ❌ Tears down ALL interfaces
/etc/init.d/networking restart            # ❌ Same as above
service networking restart                # ❌ Same as above
```

---

## 📊 Timeline of Incident

| Time | Event |
|------|-------|
| 06:30 | SESSION 58: VLAN 10 reconfiguration begins |
| 06:45 | First script attempt fails (bridge issue detected) |
| 07:00 | Second "fixed" script executed on UGREEN host |
| 07:05 | Network completely lost - all interfaces down |
| 07:10 | SSH access confirmed dead, console access needed |
| 07:15 | User connects via KVM console |
| 07:20 | /etc/network/interfaces file found missing |
| 07:25 | Network file manually recreated with printf + tee |
| 07:30 | ifreload -a successfully applied |
| 07:35 | vmbr0 confirmed UP, gateway responding |
| 07:40 | VM 100 network config restored from vmbr0.10 → vmbr0 |
| 07:45 | VM 100 started and running, INCIDENT RESOLVED |

**Total downtime:** ~40 minutes  
**Recovery method:** Manual console access + safe restoration

---

## 🔍 Root Cause Analysis

### Why Did This Happen?

1. **Insufficient Safety Culture**
   - No auto-rollback mechanism before making network changes
   - No verification of prerequisites (switch config)
   - Assumed infrastructure was ready

2. **Wrong Tool Choice**
   - Used direct file editing + systemctl restart (risky)
   - Should have used Proxmox API or web UI (built-in safety)

3. **Inadequate Deployment Process**
   - No testing on non-critical system first
   - No staged rollout
   - No post-change verification before continuing

4. **Fragile Script Design**
   - Script assumed /etc/network/interfaces could be reloaded
   - Didn't verify interfaces existed before modifying VMs
   - No error checking between steps

### What Claude Code Got Wrong

- ❌ Used `systemctl restart networking` (immediate loss of all connectivity)
- ❌ No dead-man's switch or auto-rollback timer
- ❌ No verification that vmbr0.10 actually existed before pointing VM to it
- ❌ Backup filenames with colons (shell parsing issues)
- ❌ Used heredoc syntax (fragile on remote systems)
- ❌ Didn't verify VLAN 10 was configured on UniFi switch

---

## 🎓 Key Improvements Needed

### For Claude Code Safety

1. **NEVER use `systemctl restart networking` on remote hosts**
   - Use `ifreload -a` instead
   - It's safer, doesn't tear down everything

2. **ALWAYS implement 120-second auto-rollback timer**
   - Gives opportunity to stop rollback if successful
   - Automatic recovery if connectivity lost

3. **ALWAYS verify prerequisites first**
   - Switch configuration
   - Physical port setup
   - VLAN existence on network

4. **Use safe file naming conventions**
   - Underscores instead of colons: `backup_20251229_063549`
   - No special characters that could break shell parsing

5. **Use `printf | tee` for file creation**
   - More reliable than heredoc on remote systems
   - Works in restricted shell environments

6. **Stage changes in safe order**
   - Switch configuration FIRST
   - Host configuration SECOND
   - VM configuration THIRD
   - Never all at once

---

## 📝 Session Actions Summary

✅ **Recovered vmbr0 network bridge**  
✅ **Verified gateway connectivity**  
✅ **Restored VM 100 to working network**  
✅ **Confirmed all services operational**  
✅ **Documented incident and lessons learned**  

---

## 🔗 Related Sessions

- **SESSION 58:** VLAN 10 network reconfiguration (INCIDENT TRIGGER)
- **SESSION 56:** Phase A hardening (VM 100 pre-incident state)
- **SESSION 54:** VM 100 verification and discovery

---

## ⏭️ Next Steps (When Ready)

**DO NOT attempt VLAN 10 reconfiguration yet.**

Before trying again:
1. ✅ Configure VLAN 10 on UniFi switch
2. ✅ Verify VLAN 10 from another device
3. ✅ Ensure port is properly trunked
4. ✅ Test connectivity from homelab VM 100 (10.10.10.10)
5. THEN - Use proper safe reconfiguration with auto-rollback timer

**Estimated wait:** Until VLAN 10 prerequisites are verified

---

**Status:** 🟢 INCIDENT CLOSED - SYSTEM STABLE  
**Network:** Operational and verified  
**VM 100:** Running and accessible at 192.168.40.102  
**All Systems:** Go

Generated with Claude Code  
Session 59: Network Incident Recovery & Lessons Learned
