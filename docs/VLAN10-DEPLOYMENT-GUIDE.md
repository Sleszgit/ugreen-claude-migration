# VLAN10 Safe Deployment Guide

**Status:** Ready for deployment
**Last Updated:** 2026-01-04
**Risk Level:** MEDIUM (critical infrastructure with safety net)
**Estimated Duration:** 2-3 minutes

---

## 📋 Pre-Deployment Checklist

Before running the deployment script, verify:

- [ ] You are connected via SSH to `192.168.40.60:22022`
- [ ] You have a stable internet connection
- [ ] You understand that SSH may freeze for a few seconds during the transition
- [ ] You know you have 90 seconds after applying the config to verify it's working
- [ ] You have read this entire guide
- [ ] Physical console access is NOT available (we're using automated rollback instead)

---

## 🔧 What the Script Does

The `deploy-vlan10-safe.sh` script:

1. **Creates a working backup** of your current network config
2. **Starts a "dead man's switch"** - a background process that auto-reverts after 90 seconds
3. **Pre-applies hardware fix** (ethtool) to disable VLAN offloading
4. **Applies the new network config** with VLAN awareness enabled
5. **Verifies** everything works from hardware level up to connectivity
6. **Requires you to explicitly confirm** by cancelling the dead man's switch

---

## 🛡️ How the Dead Man's Switch Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    Script Execution Timeline                     │
└─────────────────────────────────────────────────────────────────┘

Time 0:   Dead man's switch starts (90-second countdown)
          └─> Background process will revert if not cancelled

Time 10:  New network config applied
          └─> SSH may freeze for 2-5 seconds

Time 15:  Verification checks run
          └─> Hardware → Bridge → IP → Connectivity

Time 30:  If all checks pass, you see "SUCCESS"
          └─> Dead man's switch is STILL RUNNING

Time 90:  ⏰ DEADLINE - Cancel switch or auto-revert happens
          └─> Script cancels it automatically if checks passed

Result:   Configuration is permanent OR reverted
```

**Important:** The dead man's switch is a **safety net**, not a signal to act. If the script succeeds, it automatically cancels itself. If the script fails, it lets the switch do its job.

---

## 📊 What Each Verification Level Checks

The script verifies from bottom to top of the network stack:

### Level 1: Hardware (ethtool)
```bash
# Checks if VLAN offloading is actually disabled
ethtool -k nic1 | grep "rx-vlan-filter: off"
ethtool -k nic1 | grep "tx-vlan-offload: off"
```
✅ If this fails: VLAN won't work, script exits

### Level 2: Bridge Configuration
```bash
# Checks if the bridge knows about VLANs 10 and 40
bridge vlan show | grep "vmbr0.*10"
bridge vlan show | grep "vmbr0.*40"
```
✅ If this fails: Interfaces exist but not properly tagged

### Level 3: IP Addresses
```bash
# Checks if the VLAN interfaces have correct IPs
ip addr show vmbr0.40    # Should have 192.168.40.60/24
ip addr show vmbr0.10    # Should have 10.10.10.60/24
```
✅ If this fails: Routing won't work properly

### Level 4: Connectivity
```bash
# Checks if you can actually reach the network
ping -c 1 192.168.40.1   # Gateway
ping -c 1 8.8.8.8        # External (optional)
```
✅ If this fails: Network is isolated, dead man's switch reverts

---

## 🚀 Deployment Steps

### Step 1: Prepare the Configuration File

Copy the corrected configuration to the temp location where the script expects it:

```bash
# From any shell connected to UGREEN:
ssh -p 22022 ugreen-host "sudo cp /mnt/lxc102scripts/network-interfaces.vlan10.CORRECTED.new /tmp/network-interfaces.vlan10.CORRECTED.new"
```

Or if you're already on the UGREEN host:

```bash
sudo cp /mnt/lxc102scripts/network-interfaces.vlan10.CORRECTED.new /tmp/network-interfaces.vlan10.CORRECTED.new
```

**Verify it's there:**
```bash
sudo ls -lah /tmp/network-interfaces.vlan10.CORRECTED.new
```

### Step 2: Run the Deployment Script

```bash
ssh -p 22022 ugreen-host "sudo /mnt/lxc102scripts/deploy-vlan10-safe.sh"
```

The script will:
- Show you what it's about to do
- Start the dead man's switch
- Apply the configuration
- Run verification checks
- Show you SUCCESS or ERROR

### Step 3: Watch the Output Carefully

The script provides clear status indicators:

- ✅ Green check = Step passed
- ⚠️  Yellow warning = Something to be aware of, but not critical
- ❌ Red X = Critical failure, check error message
- 🛡️ Shield icon = Dead man's switch notification

### Step 4: Confirm Success

If you see this message, the deployment was successful:

```
═══════════════════════════════════════════════════════════
✅ ALL VERIFICATIONS PASSED
═══════════════════════════════════════════════════════════
```

The dead man's switch automatically cancels itself. Your network is now configured with VLAN10 support.

### Step 5: Test the New Network

Once deployment completes, you can test the VLAN10 network:

```bash
# From UGREEN host, test VLAN10 interface
ssh -p 22022 ugreen-host "ping -c 3 10.10.10.1"

# From a VM on VLAN10, ping UGREEN on VLAN10
ping -c 3 10.10.10.60
```

---

## 🚨 If Something Goes Wrong

### Scenario 1: SSH Freezes During Deployment

**This is normal.** Your SSH session may freeze for 2-5 seconds while `ifreload -a` rebuilds the network stack. Wait for it to return—this usually takes 10-15 seconds.

**If SSH doesn't return after 30 seconds:**
1. Don't panic—the dead man's switch is working
2. Wait until 90 seconds have passed since the script started
3. Try reconnecting to SSH after 90 seconds
4. You should be back on the old (working) config automatically

### Scenario 2: All Checks Pass, but You Lose Access Later

If everything passed but connectivity dies a few minutes later:

1. Try reconnecting to SSH at `192.168.40.60:22022`
2. Check if you're on the old config or new config:
   ```bash
   cat /etc/network/interfaces | grep "bridge-vlan-aware"
   ```
3. If you see `bridge-vlan-aware yes`, the new config is active
4. Run verification manually:
   ```bash
   ip addr show
   /sbin/bridge vlan show
   /sbin/ethtool -k nic1 | grep vlan
   ping -c 3 192.168.40.1
   ```

### Scenario 3: Script Exits with Error Before Applying Config

If the script fails during pre-flight checks (Steps 0-2):

- Nothing has been changed
- Your network is still working normally
- Read the error message carefully
- Fix the issue and try again

### Scenario 4: Manual Rollback Needed

If you need to manually roll back after a successful deployment:

```bash
ssh -p 22022 ugreen-host "sudo bash -c '
  BACKUP=$(ls -t /root/network-backups/interfaces.working.backup* 2>/dev/null | head -1)
  if [ -n \"\$BACKUP\" ]; then
    sudo cp \"\$BACKUP\" /etc/network/interfaces
    sudo /sbin/ifreload -a
    echo \"Rolled back to: \$BACKUP\"
  fi
'"
```

---

## 📋 What Changed in Your Network

### Before VLAN10:
```
192.168.40.60/24 (management)
└─ No VLAN segmentation
└─ No VM isolation
```

### After VLAN10:
```
vmbr0 (VLAN-aware bridge)
├─ vmbr0.40 @ 192.168.40.60/24 (management traffic)
│  └─ Gateway: 192.168.40.1
│
└─ vmbr0.10 @ 10.10.10.60/24 (guest VLANs)
   └─ Gateway: 10.10.10.1 (when VM100 is created)
```

### How Traffic Flows:

- **Untagged packets** (like SSH management) → Bridge PVID 40 → vmbr0.40 interface
- **Tagged VLAN 10 packets** → Bridge processes tag → vmbr0.10 interface
- **Physical NIC (nic1)** → VLAN offloading DISABLED (processed in kernel)

---

## 🔍 Post-Deployment Verification

After successful deployment, verify the changes persisted:

```bash
# 1. Check the configuration file was saved correctly
ssh -p 22022 ugreen-host "grep -A 2 'bridge-vlan-aware' /etc/network/interfaces"
# Should show: bridge-vlan-aware yes

# 2. Check VLAN interfaces exist
ssh -p 22022 ugreen-host "ip -c addr show | grep vmbr0"
# Should show vmbr0, vmbr0.40, and vmbr0.10

# 3. Check VLAN registration on bridge
ssh -p 22022 ugreen-host "sudo /sbin/bridge vlan show | grep vmbr0"
# Should show VLAN 10 and 40 on vmbr0

# 4. Check ethtool settings
ssh -p 22022 ugreen-host "sudo /sbin/ethtool -k nic1 | grep vlan"
# Should show both as 'off'

# 5. Verify backup was created
ssh -p 22022 ugreen-host "sudo ls -lh /root/network-backups/"
# Should show recent backup files
```

---

## 📝 Recovery Documentation

If you need to recover:

- **Working backup location:** `/root/network-backups/interfaces.working.backup.*`
- **Current config backup:** `/root/network-backups/interfaces.backup-*` (from hardened script runs)
- **Script log:** Check terminal output for detailed error messages

---

## ⏱️ Timeline & Expectations

```
0:00  - Script starts, dead man's switch activated
0:30  - Configuration applied, verifications begin
0:45  - All checks complete, success/failure result shown
1:00  - If successful, dead man's switch automatically cancelled
1:30  - Ready to proceed with VM100 creation

If failure occurs:
2:00  - 90 second timeout reached
2:15  - Network auto-reverted to working state
2:30  - You can reconnect to SSH and investigate
```

---

## ❓ FAQ

**Q: Can I run this script multiple times?**
A: Yes, it's safe. It creates a new backup each time, so you can always roll back.

**Q: What if I want to cancel before 90 seconds?**
A: If the script shows SUCCESS, it cancels automatically. If you want to force a revert before 90s, kill the background process:
```bash
pkill -f "sleep 90 && cp"
```

**Q: Will this affect my running containers/VMs?**
A: No, they continue running. But their network will briefly reconnect when ifreload -a executes.

**Q: Can I undo this later?**
A: Yes, restore from a backup:
```bash
sudo cp /root/network-backups/interfaces.working.backup.* /etc/network/interfaces
sudo /sbin/ifreload -a
```

**Q: What if the hardware offloading settings don't stick after reboot?**
A: The configuration file includes a `post-up` hook that re-applies the ethtool settings automatically on each boot. If it still doesn't work, contact your hardware vendor about the VLAN offloading bug.

---

## 🎯 Next Steps

After successful VLAN10 deployment:

1. ✅ Deployment complete
2. ⏭️ Create VM100 on VLAN10 (10.10.10.100)
3. ⏭️ Configure switch port to accept VLAN 10
4. ⏭️ Test VM100 connectivity on VLAN10 network
5. ⏭️ Migrate other infrastructure to VLAN10 as needed

---

**Questions or Issues?** Check the deployment logs:
```bash
ssh -p 22022 ugreen-host "sudo ls -lah /root/network-backups/"
ssh -p 22022 ugreen-host "sudo cat /etc/network/interfaces"
```

---

Generated: 2026-01-04
Based on: Gemini expert recommendations + corrected configuration
Script: `/mnt/lxc102scripts/deploy-vlan10-safe.sh`
