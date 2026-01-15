# Session 127: Homelab Samba Fix - Execution & Diagnostics

**Date:** 15 January 2026 @ 17:08 CET
**Duration:** ~30 minutes
**Context:** UGREEN Proxmox LXC 102 → Homelab Proxmox
**Task:** Fix Samba SMB shares on Homelab without using passwordless sudo

---

## 🎯 Objectives & Decisions

### Primary Goal
Fix Samba configuration on Homelab to expose `[FilmsHomelab]` and `[SeriesHomelab]` shares without granting passwordless sudo to additional users.

### Key Decision: Payload Method (Per Gemini Consultation)
Instead of 4 separate SSH connections (requiring 4 password prompts), consolidated all operations into a single executable script:
- **Benefit:** Only 1 password prompt required
- **Method:** Generate payload locally → SCP to remote → Execute once with sudo
- **Security:** No passwordless sudo needed

---

## 📋 Work Completed

### Part 1: Script Development & Improvement

**v1 (Original):** `/home/sleszugreen/fix-homelab-smb.sh`
- Had 4 separate SSH connections (4 password prompts needed)
- Consulted Gemini for optimization

**v2 (Remote Execution):** `/home/sleszugreen/fix-homelab-smb-v2.sh`
- Payload method: consolidate into single script
- Designed to run via SSH from LXC102

**v2-Local (Final):** `/home/sleszugreen/fix-homelab-smb-local.sh`
- Optimized for **direct execution on Homelab**
- Cleaner approach: copy script, run locally, no SSH overhead
- **This is the one we executed**

---

### Part 2: Connectivity Verification

**Initial state:** Homelab was off
- Ping: Failed (192.168.40.40 unreachable)
- SSH: Connection refused

**After Homelab startup:**
- Ping: Still unreachable from LXC102
- SSH: Successful! Connected and verified uptime: `up 1 min`

**Decision:** Run script directly on Homelab instead of via SSH from LXC102

---

### Part 3: Script Execution

**Command:** `scp fix-homelab-smb-local.sh homelab:/tmp/`
**Execution:** `ssh homelab "bash /tmp/fix-homelab-smb-local.sh"`

**Output:**
```
[1/4] Creating timestamped backup...
  ✓ Backup saved to: /etc/samba/smb.conf.bak.20260115-170700

[2/4] Applying Python fixes to Samba configuration...
  ✓ Configuration fixed

[3/4] Validating Samba configuration...
  ✓ Configuration is valid

[4/4] Restarting smbd and nmbd services...
  ✓ Services restarted successfully

✓ SAMBA CONFIGURATION FIX COMPLETE
```

**Configuration Applied:**
- Removed old `[FilmsHomelab]` and `[SeriesHomelab]` blocks
- Added corrected blocks with:
  - `force user = samba-homelab`
  - `force group = samba-homelab`
  - Proper permissions (0664/0775)

---

### Part 4: Post-Execution Diagnostics

**Problem discovered:** Windows clients still cannot connect despite successful config fix

**What verified working ✅**
- Samba daemons running (smbd PID 6140, nmbd PID 6120)
- Port 445 (SMB) listening: `0.0.0.0:445 LISTEN`
- Port 139 (NETBIOS) listening: `0.0.0.0:139 LISTEN`
- Configuration file contains both shares with correct settings
- testparm validation passed
- Directories exist: `/Seagate-20TB-mirror/FilmsHomelab` and `/SeriesHomelab`
- Directory ownership correct: `samba-homelab:samba-homelab`
- Proxmox firewall: No blocking rules detected
- Services restarted successfully

**What's failing ❌**
- Windows 11 client (192.168.99.x) cannot connect to shares
- Connection attempt times out or returns "access denied"
- Cannot list shares via smbclient from LXC102

---

## 🔍 Diagnostic Findings

### Network Environment
- Windows machine: 192.168.99.x (Desktop/Management VLAN)
- Homelab: 192.168.40.40
- Windows CAN access other SMB shares successfully:
  - \\192.168.40.20\Filmy920 ✅
  - \\192.168.40.20\Seriale2023 ✅
  - \\192.168.40.60\ugreen20tb ✅

### SMB Configuration Details
```
[FilmsHomelab]
   comment = Films Collection
   path = /Seagate-20TB-mirror/FilmsHomelab
   browseable = yes
   read only = no
   valid users = samba-homelab
   force user = samba-homelab
   force group = samba-homelab
   create mask = 0664
   directory mask = 0775

[SeriesHomelab]
   comment = Series Collection
   path = /Seagate-20TB-mirror/SeriesHomelab
   browseable = yes
   read only = no
   valid users = samba-homelab
   force user = samba-homelab
   force group = samba-homelab
   create mask = 0664
   directory mask = 0775
```

### Possible Root Causes (To Be Investigated)
1. **SMB Protocol Version Mismatch** - Windows vs Samba version incompatibility
2. **SMB Signing/Encryption** - Samba not configured for required encryption level
3. **Authentication Flow Conflict** - `valid users` + `force user` combination issue
4. **Cross-VLAN Routing** - Windows (VLAN99) → Homelab (VLAN40) firewall/routing problem
5. **Samba Security Mode** - Current `security = user` might need adjustment
6. **Windows Firewall** - Specific rule blocking this IP despite others working
7. **Directory Permissions** - 755 permissions might be too restrictive

---

## 📂 Files Created/Modified

**Created:**
- `/home/sleszugreen/fix-homelab-smb.sh` (v1 - original)
- `/home/sleszugreen/fix-homelab-smb-v2.sh` (v2 - payload remote)
- `/home/sleszugreen/fix-homelab-smb-local.sh` (v2-local - USED FOR EXECUTION)

**Modified on Homelab:**
- `/etc/samba/smb.conf` (removed old blocks, added corrected shares)
- Backup: `/etc/samba/smb.conf.bak.20260115-170700`

**Services Restarted:**
- `smbd`
- `nmbd`

---

## 🎓 Key Learnings

1. **Payload Method Works Well** - Consolidating remote operations into single script reduces SSH connections and password prompts
2. **Direct vs Remote Execution** - Running scripts directly on target server is simpler than tunneling via SSH
3. **Gemini Consultation Effective** - Identified the "4 password prompts" issue immediately
4. **No Passwordless Sudo Needed** - Can execute privileged operations interactively with single password entry
5. **Samba Configuration ≠ Accessibility** - Config can be perfect but network/firewall/protocol issues still block access

---

## ⚠️ Current Blockers & Next Steps

**Blocker:** Windows clients cannot connect to shares despite:
- Configuration being correct
- Samba services running
- Ports listening on all interfaces
- Other SMB shares from Homelab working fine (BackupFrom918)

**Next Session (128):**
1. **Consult Gemini** with comprehensive diagnostic summary
2. **Possible investigation areas:**
   - SMB protocol version requirements
   - Samba global configuration (security mode, encryption)
   - Cross-VLAN firewall rules
   - Windows-specific firewall rules
   - Test local SMB access from Homelab console

---

## 🔗 Related Sessions & Context

- **Session 126:** Initial assessment of NFS vs passwordless sudo; decision to use payload method
- **Session 125:** VM100 hardening security reviews (used Gemini consultation)
- **Session 31:** Original Homelab Samba setup (BackupFrom918 share working)
- **Session 99-101:** VLAN10 network configuration and cross-VLAN connectivity troubleshooting

---

## 📊 Session Statistics

| Item | Status |
|------|--------|
| Samba configuration fix | ✅ Completed |
| Script execution | ✅ Successful |
| Services restarted | ✅ Verified |
| Windows client access | ❌ Blocked |
| Diagnostic data gathered | ✅ Ready for consultation |
| Passwordless sudo avoided | ✅ Yes |

---

## 🚀 Next Session (128) - Planned Actions

1. **Consult Gemini** with full diagnostic summary
2. **Investigate root cause** of Windows connection failure
3. **Implement fix** based on Gemini recommendation
4. **Verify Windows access** to shares

---

**Status:** Session 127 Complete - Awaiting Gemini consultation for SMB connectivity issue
**Generated:** 15 January 2026 @ 17:08 CET
**Tokens Used:** ~15,000 / 200,000 (7.5% of weekly budget)
**Next:** Session 128 - Gemini SMB troubleshooting
