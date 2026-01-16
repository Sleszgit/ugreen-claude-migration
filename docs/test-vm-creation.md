# Test VM Creation Guide - VM100 Replication to VM150

**Date Created:** January 16, 2026
**Goal:** Create VM150 (test environment) by cloning VM100's hardened configuration to a smaller 40GB disk, isolated on VLAN 20

**Total Execution Time:** 2-3 hours (mostly automated)
**VM100 Downtime:** 10 minutes (during disk attachment phase)

---

## Executive Summary

This guide replicates VM100 (production, 100GB, fully hardened) to VM150 (test, 40GB) using a "Sync-Clone" approach:

1. **Phase 1-3:** Pre-flight checks, create empty VM150, attach VM100's disk
2. **Phase 4:** Boot VM150 with Live ISO, rsync VM100's filesystem, reinstall bootloader (MANUAL console work)
3. **Phase 5:** Cleanup and first boot VM150
4. **Phase 6:** Reconfigure VM150's identity (hostname, IPs, SSH keys) (MANUAL console work)
5. **Phase 7-8:** Test VLAN setup and service verification

**Key Benefits:**
- Preserves all Phase A + Phase B hardening (SSH, firewall, Docker, kernel, AppArmor, fail2ban, AIDE, rkhunter)
- Smaller disk (40GB) sufficient for testing
- Isolated on test VLAN 20 (no production impact)
- Fast execution (~2-3 hours vs full reinstall)

---

## Why This Approach?

**Standard Proxmox Clone Won't Work:**
- `qm clone` copies disk images byte-for-byte
- Cannot shrink 100GB source to 40GB target
- Would require full 100GB disk, then manual shrinking (slow, risky)

**Sync-Clone Method:**
- Create fresh 40GB VM150
- Boot with Live ISO (both VM100 and VM150 disks accessible)
- Use rsync to copy only used data (~9GB)
- Reinstall bootloader on new disk
- Reconfigure identity (hostname, IP, SSH keys)

**Result:** Same configuration, smaller footprint, safe execution

---

## VM100 Current State (Production)

| Property | Value |
|----------|-------|
| **Hostname** | ubuntu-docker |
| **IP/VLAN** | 10.10.10.100 / VLAN 10 |
| **SSH Port** | 22022 |
| **CPU/RAM/Disk** | 4 CPU, 16GB RAM, 100GB (9.2GB used) |
| **Services** | Docker, Portainer, Nginx Proxy Manager |
| **Hardening** | Phase A + Phase B complete |
| **Uptime** | ~1 month, stable |

---

## VM150 Target State (Test)

| Property | Value |
|----------|-------|
| **Hostname** | ugreen-docker-test |
| **IP/VLAN** | 10.20.20.150 / VLAN 20 |
| **SSH Port** | 22022 |
| **CPU/RAM/Disk** | 4 CPU, 4GB RAM, 40GB |
| **Services** | Same as VM100 (Docker, Portainer, NPM) |
| **Hardening** | All preserved from VM100 |
| **Network** | Isolated from VLAN 10 |

---

## Automation Scripts Available

Two main scripts automate this process:

### Script 1: `create-vm150-phases1-3.sh`
Automates **Phases 1-3 (Pre-flight → Disk Attachment)**

**What it does:**
- Verify VM100 disk usage
- Create VM150 on Proxmox (4 CPU, 4GB RAM, 40GB disk, VLAN 20)
- Attach Ubuntu Live ISO
- Stop VM100 temporarily
- Attach VM100's disk to VM150
- Start VM150 with Live ISO

**Usage:**
```bash
sudo bash /mnt/lxc102scripts/create-vm150-phases1-3.sh
```

**Output:**
- VM150 boots to Ubuntu Live ISO
- Both disks visible (sda=40GB new, sdb=100GB source)
- Ready for Phase 4 (filesystem sync)

**Downtime:** ~10 minutes (VM100 stopped during disk attach, then restarted)

---

### Script 2: `create-vm150-phases5-8.sh`
Automates **Phases 5-8 (Cleanup → Verification)**

**What it does:**
- Detach VM100 disk from VM150
- Remove Live ISO from VM150
- Start VM100 (restore production)
- Start VM150 (first boot from synced disk)
- Add VLAN 20 firewall rules
- Verify services and isolation

**Usage:**
```bash
sudo bash /mnt/lxc102scripts/create-vm150-phases5-8.sh
```

**Prerequisites:**
- Phase 4 must be complete (filesystem synced)
- VM150 must be shut down from Live ISO

**Output:**
- VM100 back online
- VM150 booting (status shown via console)
- VLAN 20 routes configured

---

## Manual Phase 4: Filesystem Sync (Console Work)

**Duration:** 30-60 minutes (mostly waiting for rsync)

**Prerequisite:** Phase 3 complete - VM150 booting to Live ISO with both disks attached

### Console Steps:

**Step 1: Boot to Ubuntu Live ISO**
1. Open Proxmox console for VM150
2. System boots to Ubuntu "Try or Install" menu
3. Select "Try Ubuntu" (to get shell)
4. Wait for desktop
5. Open terminal (Ctrl+Alt+T or Applications → Terminal)

**Step 2: Identify Disks**
```bash
lsblk
# You should see:
# sda      40GB (new VM150 disk)
# sdb     100GB (source VM100 disk)
```

**Step 3: Partition New Disk (sda)**
```bash
# Create GPT partition table
sudo parted /dev/sda mklabel gpt

# Create EFI partition (1GB)
sudo parted /dev/sda mkpart primary fat32 1MiB 1GiB
sudo parted /dev/sda set 1 esp on

# Create root partition (remaining ~39GB)
sudo parted /dev/sda mkpart primary ext4 1GiB 100%

# Verify partitions
sudo parted /dev/sda print
```

**Step 4: Format Partitions**
```bash
# EFI partition
sudo mkfs.vfat -F32 /dev/sda1

# Root partition
sudo mkfs.ext4 /dev/sda2
```

**Step 5: Mount Filesystems**
```bash
# Create mount points
sudo mkdir -p /mnt/target /mnt/source

# Mount new disk (target)
sudo mount /dev/sda2 /mnt/target
sudo mkdir -p /mnt/target/boot/efi
sudo mount /dev/sda1 /mnt/target/boot/efi

# Mount source disk
sudo mount /dev/sdb2 /mnt/source
sudo mount /dev/sdb1 /mnt/source/boot/efi

# Verify
mount | grep "/mnt"
```

**Step 6: Sync Filesystem with rsync**
```bash
# Copy all files from source to target (excluding system dirs)
sudo rsync -axHAX --info=progress2 \
  --exclude=/proc/* \
  --exclude=/sys/* \
  --exclude=/dev/* \
  --exclude=/run/* \
  --exclude=/tmp/* \
  --exclude=/mnt/* \
  --exclude=/media/* \
  --exclude=/lost+found \
  /mnt/source/ /mnt/target/

# WAIT for this to complete (15-30 minutes depending on disk speed)
# Output will show progress and speed: "sent X.XXG bytes  received Y.YY bytes  Z.ZZM/sec"
```

**Step 7: Update UUIDs in fstab**
```bash
# Get new disk UUIDs
NEW_ROOT_UUID=$(sudo blkid /dev/sda2 -s UUID -o value)
NEW_EFI_UUID=$(sudo blkid /dev/sda1 -s UUID -o value)

echo "New Root UUID: $NEW_ROOT_UUID"
echo "New EFI UUID: $NEW_EFI_UUID"

# Update fstab
sudo sed -i "s|UUID=[a-zA-Z0-9-]*\s*/\s*|UUID=$NEW_ROOT_UUID / |" /mnt/target/etc/fstab
sudo sed -i "s|UUID=[a-zA-Z0-9-]*\s*/boot/efi\s*|UUID=$NEW_EFI_UUID /boot/efi |" /mnt/target/etc/fstab

# Verify changes
echo "Updated fstab:"
cat /mnt/target/etc/fstab | grep -E "^UUID|^#"
```

**Step 8: Reinstall GRUB Bootloader**
```bash
# Bind necessary filesystems for chroot
sudo mount --bind /dev /mnt/target/dev
sudo mount --bind /proc /mnt/target/proc
sudo mount --bind /sys /mnt/target/sys

# Chroot into the new system
sudo chroot /mnt/target

# Inside chroot:
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu
update-grub
exit

# Unmount bind mounts
sudo umount /mnt/target/dev
sudo umount /mnt/target/proc
sudo umount /mnt/target/sys
```

**Step 9: Unmount and Shutdown**
```bash
# Unmount all filesystems
sudo umount /mnt/target/boot/efi
sudo umount /mnt/target
sudo umount /mnt/source/boot/efi
sudo umount /mnt/source

# Verify unmounted
mount | grep "/mnt"  # Should show nothing

# Shutdown to prepare for Phase 5
sudo poweroff
```

**What to Watch For:**
- ✅ Rsync completes with "Total transferred: X.XXG bytes"
- ✅ GRUB installs without errors
- ✅ All filesystems properly unmounted before shutdown
- ❌ If rsync hangs: Press Ctrl+C, check disk space with `df -h /mnt/target`
- ❌ If GRUB fails: UUID mismatch likely - verify fstab manually

---

## Manual Phase 6: Post-Clone Reconfiguration (Console Work)

**Duration:** 10-15 minutes

**Prerequisite:** Phase 5 complete - VM150 boots successfully from disk

### Console Steps:

**Step 1: Access VM150 Console**
1. Open Proxmox console for VM150
2. VM150 should boot and present login prompt
3. Login as your user (default: sleszugreen)

**Step 2: Update Hostname**
```bash
# View current hostname
hostname
# Output: ubuntu-docker

# Change to new hostname
sudo hostnamectl set-hostname ugreen-docker-test

# Verify
hostname
# Output should be: ugreen-docker-test
```

**Step 3: Update /etc/hosts**
```bash
# Update references to old hostname
sudo sed -i 's/ubuntu-docker/ugreen-docker-test/g' /etc/hosts

# Verify
cat /etc/hosts
# Should show: 127.0.0.1 ugreen-docker-test
```

**Step 4: Regenerate Machine ID**
```bash
# This prevents systemd conflicts (journal, DBus, etc.)
sudo rm /etc/machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id

# Verify new ID is different from VM100
cat /etc/machine-id
```

**Step 5: Regenerate SSH Host Keys**
```bash
# Security best practice: new host keys for test environment
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server

# Verify keys exist
ls -la /etc/ssh/ssh_host_* | wc -l
# Output should be: 6 (RSA, ED25519, ECDSA pairs)
```

**Step 6: Update Network Configuration**
```bash
# Edit netplan configuration for VLAN 20
sudo nano /etc/netplan/00-installer-config.yaml
```

**What to change in editor:**
```yaml
# OLD (from VM100)
network:
  version: 2
  ethernets:
    ens18:
      addresses:
        - 10.10.10.100/24
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses:
          - 192.168.40.50
          - 192.168.40.30

# NEW (for test VLAN)
network:
  version: 2
  ethernets:
    ens18:
      addresses:
        - 10.20.20.150/24
      routes:
        - to: default
          via: 10.20.20.1
      nameservers:
        addresses:
          - 192.168.40.50
          - 192.168.40.30
```

**Changes to make:**
1. Line with `10.10.10.100` → Change to `10.20.20.150`
2. Line with `10.10.10.1` → Change to `10.20.20.1`

**Save:** Ctrl+X, then Y, then Enter

**Step 7: Apply Network Configuration**
```bash
# Test syntax
sudo netplan try

# If no errors after 120 seconds, connection is confirmed
# (It will auto-apply or ask you to confirm)

# Or apply permanently
sudo netplan apply

# Verify new IP
ip addr show ens18
# Output: inet 10.20.20.150/24
```

**Step 8: Verify All Changes**
```bash
# Summary of changes
echo "=== Verification ===" && \
echo "Hostname:" && hostname && \
echo "" && \
echo "Machine ID:" && cat /etc/machine-id && \
echo "" && \
echo "IP Address:" && ip addr show ens18 | grep "inet " && \
echo "" && \
echo "SSH Keys:" && ls /etc/ssh/ssh_host_* | wc -l
```

**What to Expect:**
- Hostname: ugreen-docker-test
- Machine ID: 32-character hex value (unique, different from VM100)
- IP: 10.20.20.150/24
- SSH Keys: 6 files (new)

---

## Execution Checklist

### Before Starting
- [ ] VM100 is running and accessible at 10.10.10.100:22022
- [ ] Proxmox console access available
- [ ] SSH access to UGREEN host (`ssh ugreen-host`)
- [ ] Ubuntu 24.04 Live ISO available in Proxmox (local:iso/ubuntu-24.04-live-server-amd64.iso)

### Phases 1-3 Automation
- [ ] Run: `sudo bash /mnt/lxc102scripts/create-vm150-phases1-3.sh`
- [ ] Script completes without errors
- [ ] VM150 boots to Ubuntu Live ISO (verify in console)
- [ ] Both disks visible in `lsblk` (sda 40GB, sdb 100GB)
- [ ] VM100 automatically restarted (verify online: `ssh -p 22022 10.10.10.100 "echo OK"`)

### Phase 4 Manual Sync (Console)
- [ ] Access VM150 console
- [ ] Boot to Ubuntu Live, open terminal
- [ ] Run all 9 steps (partition, format, mount, rsync, UUID update, GRUB, unmount)
- [ ] Rsync completes successfully (~20-30 minutes)
- [ ] GRUB installed without errors
- [ ] Shutdown VM150 when done

### Phases 5-8 Automation
- [ ] Run: `sudo bash /mnt/lxc102scripts/create-vm150-phases5-8.sh`
- [ ] Script completes without errors
- [ ] VM100 confirmed online
- [ ] VM150 boots and reaches login prompt
- [ ] VLAN 20 routes configured

### Phase 6 Manual Reconfiguration (Console)
- [ ] Access VM150 console
- [ ] Run all 8 steps (hostname, /etc/hosts, machine-id, SSH keys, netplan, verification)
- [ ] All changes verified

### Verification
- [ ] `ssh -p 22022 10.10.10.100 "echo 'VM100 OK'"` - succeeds
- [ ] `ssh -p 22022 10.20.20.150 "echo 'VM150 OK'"` - succeeds
- [ ] `ssh -p 22022 10.20.20.150 "hostname"` - outputs "ugreen-docker-test"
- [ ] `ssh -p 22022 10.20.20.150 "docker run --rm hello-world"` - succeeds
- [ ] `ssh -p 22022 10.20.20.150 "sudo systemctl status fail2ban"` - active
- [ ] `ssh -p 22022 10.20.20.150 "ping -c 1 10.10.10.100"` - FAILS (isolation verified)

---

## Rollback / Emergency Recovery

**If something breaks:**

### Option 1: Delete and Restart
```bash
# Stop VM150
ssh ugreen-host "sudo qm stop 150"

# Delete VM150
ssh ugreen-host "sudo qm destroy 150"

# VM100 is unaffected (disk was only borrowed, not modified)
# Restart plan from Phases 1-3
```

### Option 2: Undo Network Reconfiguration (Phase 6)
```bash
# If Phase 6 network changes break things, revert:
ssh -p 22022 10.20.20.150 "sudo nano /etc/netplan/00-installer-config.yaml"

# Change IP back to 10.10.10.100/24, via 10.10.10.1
# Then: sudo netplan apply
```

### Option 3: Boot VM150 to Live ISO Again
```bash
# If VM150 won't boot:
ssh ugreen-host "sudo qm set 150 --boot order=ide2;sata0"
ssh ugreen-host "sudo qm set 150 --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom"
ssh ugreen-host "sudo qm start 150"

# Then reconfigure via console and chroot into /mnt/target to fix issues
```

---

## Key Decisions & Rationale

| Decision | Rationale |
|----------|-----------|
| **VLAN 20 for test** | Isolation from production VLAN 10, prevents accidental impacts |
| **4GB RAM (vs 16GB)** | Sufficient for testing, reduces resource usage |
| **40GB disk (vs 100GB)** | Saves storage, still 4x the actual usage (9GB) |
| **Same SSH port (22022)** | Familiar, already hardened from Phase A |
| **Rsync approach** | Much faster than full reinstall, preserves all hardening |
| **Machine-ID regen** | Prevents systemd/journal/DBus conflicts with VM100 |
| **SSH keys regen** | Security best practice for cloned systems |

---

## Support & Troubleshooting

### Problem: Phase 3 Fails - VM100 Won't Stop
```bash
# Try graceful shutdown first
ssh -p 22022 10.10.10.100 "sudo shutdown -h now"

# Wait 30 seconds, then try script again
sudo bash /mnt/lxc102scripts/create-vm150-phases1-3.sh
```

### Problem: Phase 4 - Rsync Hangs or Very Slow
```bash
# Check source disk is still mounted
sudo mount | grep sdb2

# Check destination disk has space
df -h /mnt/target

# If source unmounted somehow, remount:
sudo mount /dev/sdb2 /mnt/source
sudo mount /dev/sdb1 /mnt/source/boot/efi
```

### Problem: Phase 4 - GRUB Install Fails
```bash
# Most common issue: UUID mismatch in fstab
# Verify fstab inside chroot:
sudo chroot /mnt/target
mount | grep sda
cat /etc/fstab | grep UUID
exit

# If UUIDs don't match, fix manually:
sudo blkid /dev/sda1 /dev/sda2
# Update fstab with correct UUIDs
```

### Problem: Phase 5 - VM150 Won't Boot
```bash
# Check boot configuration
ssh ugreen-host "sudo qm config 150 | grep -E 'boot|sata'

# Boot to Live ISO for recovery
ssh ugreen-host "sudo qm set 150 --boot order=ide2;sata0"
ssh ugreen-host "sudo qm set 150 --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom"
ssh ugreen-host "sudo qm start 150"

# Boot, mount /dev/sda2 to /mnt/target, chroot, fix issues
```

### Problem: Phase 6 - Network Config Won't Apply
```bash
# Test syntax
sudo netplan try

# If fails, revert and check format
sudo nano /etc/netplan/00-installer-config.yaml
# Ensure proper YAML indentation (2 spaces per level)

# Try again
sudo netplan apply
```

### Problem: VM150 Accessible but Isolated from VLAN 10 (Can't Reach VM100)
**This is correct!** VLAN 20 is intentionally isolated. If you need VM150 to reach VM100:
```bash
# Add cross-VLAN route on UGREEN host
ssh ugreen-host "sudo ufw route allow from 10.20.20.0/24 to 10.10.10.0/24"
```

But for a test environment, isolation is preferred.

---

## Next Steps After Successful Completion

### Immediate
- [ ] Document any customizations made to VM150
- [ ] Test your specific workload on VM150
- [ ] Verify all necessary services are accessible

### Optional Optimizations
- [ ] Create VM150 template snapshot for future test VMs
- [ ] Document VLAN 20 setup for other test environments
- [ ] Add monitoring to VM150 test metrics

### Production Use
- When satisfied with tests, VM150 can be promoted to production by:
1. Changing hostname to production name
2. Moving to production VLAN (VLAN 10)
3. Updating any required IPs/configuration
4. Running Phase A scripts if different hardening profile needed

---

## References

**Files Modified:**
- VM150 created: `/dev/zvol/nvme2tb/vm-150-disk-1` (40GB)
- VM150 EFI: `/dev/zvol/nvme2tb/vm-150-disk-0` (1M)
- VM150 config: Proxmox `/etc/pve/qemu-server/150.conf`

**Scripts Used:**
- `/mnt/lxc102scripts/create-vm150-phases1-3.sh` - Automation for phases 1-3
- `/mnt/lxc102scripts/create-vm150-phases5-8.sh` - Automation for phases 5-8

**Documentation:**
- This guide: `/home/sleszugreen/docs/test-vm-creation.md`
- Original plan: `/home/sleszugreen/.claude/plans/woolly-inventing-sutton.md`

**Contact:**
- Issues during execution? Check troubleshooting section above
- Stuck? Review the plan file for full technical details

---

**Guide Created:** January 16, 2026
**Last Updated:** January 16, 2026
**Status:** Ready for execution

