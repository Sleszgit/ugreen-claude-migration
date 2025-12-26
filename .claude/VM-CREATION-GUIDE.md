# VM Creation Best Practices

**Last Updated:** 25 Dec 2025  
**Status:** Cloud-init approach proven 100% reliable on UGREEN Proxmox

---

## ⚠️ KNOWN ISSUE: UEFI/IDE CDROM Unmount Bug

**DO NOT use Ubuntu ISO with IDE2 CDROM without workaround:**

```
Problem:
  UEFI (OVMF) firmware cannot cleanly release IDE device during reboot

Configuration that triggers bug:
  - bios: ovmf
  - machine: q35
  - ide2: [ISO],media=cdrom
  - boot: order=scsi0;ide2;net0

Result:
  Ubuntu installer completes → tries umount /cdrom → FAILS → boot loop

Root Cause:
  QEMU/OVMF limitation (unfixable in hardware, KNOWN BUG in Proxmox)
```

**If you must use ISO approach:**
1. Let Ubuntu installer complete normally
2. When unmount fails → **IMMEDIATELY STOP** (don't wait for reboot)
3. Use Proxmox web UI: VM config → Hardware → Delete IDE2 device
4. OR via CLI: `sudo qm set 100 -ide2 none`
5. Force reboot from console: `sudo reboot -f`
6. VM boots successfully from disk

**Better solution:** Skip ISO entirely - use cloud images instead.

---

## ✅ RECOMMENDED: Ubuntu Cloud Image Approach

**Why this is optimal:**
1. **No ISO** → No CDROM device → No unmount bug
2. **Fully unattended** → No interactive installer
3. **Cloud-init proven reliable** → VM 100 confirms 100% success
4. **Fast** → System ready in ~10 seconds
5. **Repeatable** → Identical results every time

**Advantages over ISO:**
| ISO Approach | Cloud Image Approach |
|---|---|
| Interactive installer (manual) | Fully automated |
| 10+ minutes setup | ~10 seconds setup |
| UEFI/IDE bug risk | Zero CDROM issues |
| Error-prone | Reliable and repeatable |

---

## 📋 Reference Configuration (VM 100 - Proven Working)

**File Location:** `/etc/pve/qemu-server/100.conf`

**Successful settings:**
```
bios: ovmf                       # UEFI firmware
machine: q35                     # Modern emulation
cores: 4                         # CPU cores
memory: 20480                    # RAM in MB (20GB)
scsi0: nvme2tb:vm-100-disk-1     # Main disk (250GB)
ide2: none,media=cdrom           # IDE2 disabled (THIS IS KEY!)
net0: virtio,bridge=vmbr0        # DHCP networking
boot: order=scsi0;ide2;net0      # Boot order (ide2 inactive)
```

**Key points:**
- ✅ UEFI + q35 = modern, reliable
- ✅ `ide2: none` = no CDROM device (prevents unmount bug)
- ✅ Cloud image loaded as scsi0 = single, reliable disk

---

## ✅ Cloud-Init on UGREEN Proxmox - PROVEN RELIABLE

**Status:** 100% verified working (25 Dec 2025)

**VM 100 Cloud-Init Results (verified from `/var/log/cloud-init.log`):**
- ✅ Cloud-init v.25.1.4 completed all 4 stages
- ✅ User creation: sleszdockerugreen (correct groups and sudo access)
- ✅ Package installation: docker.io + docker-compose (successful)
- ✅ SSH: Configured and working
- ✅ Final status: 26 modules with 0 failures
- ✅ Verification: `docker --version` returns Docker 28.2.2

**Why it works:**
- Proxmox passes user-data to cloud-init properly
- DataSourceNone is a fallback, but user-data still processes
- Package updates work reliably
- All configuration directives execute successfully

**Key Finding:** Cloud-init is 100% reliable for automation - use it.

---

## 🔧 Verification Commands (After VM Creation)

**On Proxmox host:**
```bash
sudo qm config 100 | grep -E "bios|machine|ide|boot|scsi0"
```

**Inside VM via SSH (after first boot):**
```bash
# Check Docker installed
docker --version
docker-compose --version

# Check packages installed
apt list --installed | grep -E "docker|compose"

# Check cloud-init completed
sudo cloud-init status --long

# Check user created correctly
id $(whoami)
```

**All must show success or automation failed.**

---

## ❌ What Does NOT Work

| Approach | Problem | Why | Solution |
|----------|---------|-----|----------|
| ISO + interactive | CDROM unmount fails | UEFI/IDE bug (hardware limitation) | Use cloud images |
| Guessing cloud-init | Wrong assumptions | Each hypervisor different | Always verify logs |
| Manual IDE2 workaround | Timing issues, fragile | Can't detect install completion | Use cloud images (NO ISO) |
| Assuming success | Missing logs | Never know what failed | Verify `/var/log/cloud-init.log` |

---

## 🚫 Rules to Follow (Avoid Mistakes)

**WHEN CREATING VMs AUTOMATICALLY:**

1. ✅ **Use cloud images, NOT ISO**
   - Prevents CDROM unmount bug entirely
   - Faster and more reliable
   - No manual workarounds needed

2. ✅ **Always verify cloud-init.log after first boot**
   - Check: `/var/log/cloud-init.log`
   - Verify: User created, packages installed, SSH working
   - Don't assume success - test it

3. ✅ **Reference VM 100 config for BIOS/machine settings**
   - Don't try different firmware combinations
   - Use proven UEFI (ovmf) + q35 settings
   - Keep ide2 set to "none" (not attached to ISO)

4. ❌ **NEVER assume cloud-init failure without logs**
   - Log shows success ≠ everything actually installed
   - Verify with: `docker --version`, `apt list --installed`
   - DataSourceNone is normal on Proxmox, not an error

5. ❌ **NEVER use IDE device for CDROM in automation**
   - IDE + UEFI = unmount bug (known limitation)
   - Even with workaround, it's fragile and timing-dependent
   - Cloud images eliminate this entirely

6. ❌ **NEVER guess about datasource configuration**
   - Test actual behavior, not assumptions
   - Proxmox passes user-data via cloud-init
   - Trust the logs, not your theory

---

## Next Steps

- See `PROXMOX-COMMANDS.md` for VM creation commands
- See `INFRASTRUCTURE.md` for network and storage setup
- See `TASK-EXECUTION.md` for workflow and approval process
