# SSH MobaXterm Access Fix - Session Summary

**Date:** 2025-12-13
**System:** UGREEN Proxmox Host (192.168.40.60)
**User:** sleszugreen
**Issue:** MobaXterm SSH connection failed while Git CMD works

---

## Problem Description

**Symptom:**
- MobaXterm SSH connection to 192.168.40.60 fails with error:
  ```
  No supported authentication methods available (server sent: publickey)
  ```
- Git CMD on same Windows 11 machine connects successfully
- Both attempting to connect to Proxmox host at 192.168.40.60

**Root Causes Identified:**

1. **Server-side:** Malformed `authorized_key` file (typo - missing 's')
   - File `/home/sleszugreen/.ssh/authorized_key` contained broken SSH key with line breaks
   - Correct file should be `authorized_keys` (plural)

2. **Client-side:** MobaXterm not configured to use SSH private key
   - Git CMD automatically uses keys from `%USERPROFILE%\.ssh\`
   - MobaXterm requires explicit key configuration

---

## Server Configuration

**SSH Settings (/etc/ssh/sshd_config):**
- Port: 22022 (custom, hardened)
- PasswordAuthentication: no
- PubkeyAuthentication: yes
- PermitRootLogin: prohibit-password
- SSH service: Active and running

**Authorized Keys Before Fix:**
```
~/.ssh/authorized_key (TYPO - incorrect filename)
  - Malformed key with line breaks

~/.ssh/authorized_keys (correct filename)
  - Single valid key
```

---

## Solutions Applied

### 1. Fixed Server-Side SSH Keys

**Actions Taken:**

```bash
# Consolidated and fixed authorized_keys
cat > ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMv5ZdKSB8NrjRa04LAK1ePTpnnApTyC44RCxoJSp1a+ desktop-ugreen-nas
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiVWHf9y7YPA89SWzUI7gJoEHV9w/PPuV/OtlRI41tv sleszugreen@ugreen
EOF

# Removed typo file
rm ~/.ssh/authorized_key

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys
```

**Result:**
- Cleaned up SSH key configuration
- Both valid keys now properly formatted in correct file
- Typo file removed to prevent confusion

### 2. MobaXterm Configuration (Pending User Action)

**Windows Client Steps Required:**

1. **Locate SSH private key on Windows:**
   ```cmd
   dir %USERPROFILE%\.ssh
   ```
   Look for: `id_ed25519` or `id_rsa` (private key, NO .pub extension)

2. **Configure MobaXterm:**
   - Open MobaXterm
   - Session → SSH
   - Remote host: 192.168.40.60
   - Port: 22022
   - Username: sleszugreen (or root)
   - Advanced SSH settings tab
   - "Use private key": Browse to `C:\Users\[username]\.ssh\id_ed25519`

3. **Test connection**

---

## Technical Details

### Environment
- **Proxmox Host:** UGREEN DXP4800+ (192.168.40.60)
- **OS:** Debian GNU/Linux 13 (Trixie)
- **SSH Daemon:** OpenSSH, listening on port 22022
- **Authentication:** Public key only (password disabled)

### Key Files Locations
- **Server:** `/home/sleszugreen/.ssh/authorized_keys`
- **Windows Client:** `%USERPROFILE%\.ssh\id_ed25519` (typical location)

### SSH Port
- **Custom port:** 22022 (security hardening)
- **Must specify in MobaXterm:** Port field = 22022

---

## Why Git CMD Works vs MobaXterm

**Git CMD (Git Bash):**
- Uses OpenSSH client built into Git for Windows
- Automatically searches `~/.ssh/` for private keys (`id_ed25519`, `id_rsa`, etc.)
- Reads `~/.ssh/config` if present
- No manual configuration needed

**MobaXterm:**
- Has its own SSH client implementation
- Does NOT automatically search Windows `.ssh` folder
- Requires explicit private key path configuration
- More secure approach (explicit > implicit) but requires setup

---

## Status

**Completed:**
- ✅ Fixed server-side authorized_keys file
- ✅ Removed malformed key file
- ✅ Set correct permissions (600)
- ✅ Verified SSH service running on port 22022
- ✅ Located Windows SSH keys directory

**Pending:**
- ⏳ Identify which key matches server authorized_keys
- ⏳ User to configure MobaXterm with correct private key path
- ⏳ Test MobaXterm connection

---

## Windows SSH Keys Found

**Location:** `C:\Users\jakub\.ssh\`

**Available Keys:**
```
id_ed25519              (464 bytes - private key)
id_ed25519.pub          (96 bytes - public key)
id_ed25519_ugreen       (464 bytes - private key) ⭐ LIKELY MATCH
id_ed25519_ugreen.pub   (101 bytes - public key)
mobax_proxmox           (464 bytes - private key)
mobax_proxmox.pub       (97 bytes - public key)
mobax_proxmox2.ppk      (460 bytes - PuTTY format)
proxmox.ppk             (458 bytes - PuTTY format)
ugreen_key              (411 bytes - might be private key)
ugreen_key.txt          (416 bytes - text format)
ugreen_key_new.txt      (416 bytes - text format)
id_devman               (411 bytes)
eace4e2ab8              (1766 bytes)
config                  (272 bytes - SSH config file)
```

**Key Candidates for MobaXterm:**
1. **`id_ed25519_ugreen`** - Most likely match (named for UGREEN)
2. **`mobax_proxmox`** - Previously created for MobaXterm
3. **`id_ed25519`** - Generic key

**Notes:**
- `.ppk` files are PuTTY format (MobaXterm can use these)
- OpenSSH format keys (without .ppk) are preferred
- User has SSH config file that Git CMD might be reading

---

## Next Steps

1. **Identify matching key by checking public keys:**
   ```cmd
   type C:\Users\jakub\.ssh\id_ed25519_ugreen.pub
   type C:\Users\jakub\.ssh\mobax_proxmox.pub
   type C:\Users\jakub\.ssh\id_ed25519.pub
   ```
   Compare output to server's authorized_keys

2. **Configure MobaXterm** with matching private key

3. **Test connection** to 192.168.40.60:22022

---

## Learning Points

1. **File naming matters:** `authorized_key` vs `authorized_keys` - SSH only reads the correct plural form
2. **SSH keys must be single-line:** Line breaks in public keys break authentication
3. **Different SSH clients behave differently:** Git CMD auto-discovers keys, MobaXterm requires explicit config
4. **Security is multi-layered:** Server config (keys only) + client config (providing the key)

---

## Related Documentation

- SSH Configuration: `/etc/ssh/sshd_config`
- Proxmox Setup: `~/projects/proxmox-hardening/`
- User Instructions: `~/.claude/CLAUDE.md`

---

## Key Identification Results

**Matching Key Found:**
- **id_ed25519_ugreen** - Public key matches server authorized_keys
  - `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMv5ZdKSB8NrjRa04LAK1ePTpnnApTyC44RCxoJSp1a+ desktop-ugreen-nas`
  - **ISSUE:** Protected with passphrase (user doesn't remember setting one)

**Other keys checked:**
- mobax_proxmox.pub: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIR4zNSLVkh+iv3aB7vvJgLk6cjkCZnjl1aLaIH2JPQ9` - No match
- id_ed25519.pub: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMrbqCQUe383r/tEtY4HpErQtkIasECDzEu5ImvjgsJm` - No match

## New Discovery: Git CMD Uses SSH Config

**Hypothesis:** Git CMD works because it's reading `C:\Users\jakub\.ssh\config`, not auto-discovering keys.

The SSH config file (272 bytes) likely specifies:
- Which key to use for 192.168.40.60
- Port configuration (22022)
- Possibly a different key or passphrase handling

---

**Session Status:** Blocked - Passphrase issue with id_ed25519_ugreen key
**Next Session Options:**
1. Check SSH config file content to see which key Git CMD actually uses
2. Add mobax_proxmox.pub to server and use that key instead
3. Generate new passwordless key specifically for MobaXterm
