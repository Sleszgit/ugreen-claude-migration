# Session 121: SMB Shares Diagnosis - FilmsHomelab & SeriesHomelab Access Issue

**Date:** 14 January 2026
**Time:** ~16:30 CET
**Objective:** Diagnose why Windows cannot access FilmsHomelab and SeriesHomelab SMB shares on homelab Proxmox
**Status:** ✅ Root cause identified, solution documented for Gemini consultation

---

## Problem Statement

**User Issue:** Windows (Total Commander) cannot access SMB shares on homelab:
- `\\192.168.40.40\FilmsHomelab`
- `\\192.168.40.40\SeriesHomelab`

**Symptoms:**
- Connection hangs for extended period
- Timeout error: "drive is not found"
- Must select another drive in Total Commander
- Other shares (BackupFrom918) work fine

---

## Diagnostic Findings

### Services & Network (✅ All Working)
- Samba services running: `smbd`, `nmbd` (active since Jan 14 15:02:30 CET)
- Listening on SMB ports: `445/tcp`, `139/tcp` (IPv4 & IPv6)
- Network connectivity: Verified from LXC 102 (can enumerate shares)
- Samba can list shares:
  ```
  BackupFrom918   Disk      Backup from 918 NAS    ✅ Working
  FilmsHomelab    Disk      Films Collection       ❌ Failing
  SeriesHomelab   Disk      Series Collection      ❌ Failing
  IPC$            IPC       IPC Service
  ```

### Storage & Filesystem (✅ All Present)
- **FilmsHomelab Dataset:**
  - Path: `/Seagate-20TB-mirror/FilmsHomelab`
  - Size: 3.17TB used, 9.51TB available
  - Ownership: `root:root`
  - Permissions: `755` (drwxr-xr-x)
  - Status: ✅ Mounted, readable

- **SeriesHomelab Dataset:**
  - Path: `/Seagate-20TB-mirror/SeriesHomelab`
  - Size: 3.91TB used, 9.51TB available
  - Ownership: `ugreen-homelab-ssh:ugreen-homelab-ssh`
  - Permissions: `755` (drwxr-xr-x)
  - Status: ✅ Mounted, readable

### Samba Configuration Issue (❌ Root Cause)

**Config excerpt from `/etc/samba/smb.conf`:**
```
[global]
   security = user
   map to guest = never        ← CRITICAL: Rejects unauthenticated connections

[BackupFrom918]  ✅ WORKS
   path = /WD10TB/918backup2512
   read only = no
   valid users = samba-homelab  ← HAS authentication config

[FilmsHomelab]  ❌ FAILS
   path = /Seagate-20TB-mirror/FilmsHomelab
   read only = no
   # MISSING: valid users or guest ok

[SeriesHomelab]  ❌ FAILS
   path = /Seagate-20TB-mirror/SeriesHomelab
   read only = no
   # MISSING: valid users or guest ok
```

---

## Root Cause Analysis

**Why Windows Connection Hangs:**

1. Windows initiates SMB protocol handshake on port 445 ✅
2. Samba server responds, begins authentication negotiation
3. Samba checks share configuration: "What auth is allowed here?"
4. **FilmsHomelab/SeriesHomelab have NO authentication directive** (no `valid users`, no `guest ok`)
5. Samba checks global policy: `map to guest = never`
6. Result: **Connection is rejected**
7. Windows waits for response → **Timeout after ~30 seconds → "drive not found"**

**Comparison:**
- BackupFrom918 works because `valid users = samba-homelab` explicitly allows auth
- FilmsHomelab/SeriesHomelab fail because auth is unconfigured AND `map to guest = never` blocks fallback

---

## Solution

**Add authentication configuration to both shares:**

Edit `/etc/samba/smb.conf` on homelab console:
```bash
sudo nano /etc/samba/smb.conf
```

Modify the two shares:
```
[FilmsHomelab]
   path = /Seagate-20TB-mirror/FilmsHomelab
   read only = no
   guest ok = yes           ← ADD THIS LINE

[SeriesHomelab]
   path = /Seagate-20TB-mirror/SeriesHomelab
   read only = no
   guest ok = yes           ← ADD THIS LINE
```

Validate and restart:
```bash
sudo testparm           # Validates config syntax
sudo systemctl restart smbd nmbd
```

**Expected Result:** Windows should immediately connect without hang.

---

## Pending Items

- **Gemini Consultation Prepared:** Summary document created for user to consult with Gemini WebUI on:
  1. Should we use `guest ok = yes` or `valid users = samba-homelab`?
  2. Security implications of each approach
  3. Whether to modify global `map to guest` setting instead

- **Secondary Fix (if authenticated access chosen):**
  - Directory ownership may need adjustment for `samba-homelab` user
  - Currently: FilmsHomelab owned by root, SeriesHomelab owned by ugreen-homelab-ssh
  - May need: `sudo chown -R samba-homelab:samba-homelab` on both

---

## Files Modified

None (diagnostic session only - all commands read-only)

## Next Steps

1. User executes fix on homelab console (add `guest ok = yes` lines)
2. Consult Gemini on authentication approach preference
3. Verify Windows access post-fix
4. If access still fails, check directory ownership/permissions

---

## Session Timeline

| Time | Action | Result |
|------|--------|--------|
| 16:30 | Check Samba config | Found shares defined, services running |
| 16:35 | List SMB shares | All 3 shares visible, backupFrom918 working |
| 16:40 | Check storage/ZFS | Both datasets present, properly mounted |
| 16:45 | Check firewall | Ports 445/139 open, listening |
| 16:50 | Analyze auth config | Identified missing `valid users` / `guest ok` |
| 16:55 | Root cause confirmed | `map to guest = never` blocks auth negotiation |
| 17:00 | Solution documented | Summary prepared for Gemini consultation |

---

**Session completed:** 14 January 2026, ~17:00 CET
