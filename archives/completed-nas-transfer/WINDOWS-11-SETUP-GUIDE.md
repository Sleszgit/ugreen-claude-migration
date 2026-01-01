# Windows 11 - UGREEN NAS Connection Guide

**Access your UGREEN media from Windows 11 like a local drive!**

---

## Step 1: Run Setup Script on UGREEN

First, we need to install and configure Samba on the UGREEN server.

**On the UGREEN (where you are now):**

```bash
# Make the script executable
chmod +x ~/setup-windows-access.sh

# Run the setup script
sudo bash ~/setup-windows-access.sh
```

**What it will do:**
1. Install Samba server
2. Create 3 SMB shares (Movies918, Series918, Media)
3. Ask you to set a password for Windows access
4. Start the Samba service
5. Configure firewall (if needed)

**Note:** The Samba password can be different from your Linux password. Choose something memorable for Windows access.

---

## Step 2: Connect from Windows 11

### Method 1: Map Network Drive (Recommended)

**This creates a permanent drive letter (like Z:) for your UGREEN media.**

1. **Open File Explorer** (Windows Key + E)

2. **Click on "This PC"** in the left sidebar

3. **Click the three dots (•••)** at the top, then select **"Map network drive"**
   - Or: Right-click "This PC" → "Map network drive"

4. **Choose a drive letter** (e.g., Z:)

5. **Enter the folder path:**
   ```
   \\192.168.40.60\Movies918
   ```
   (Or use `Series918` or `Media` instead)

6. **Check these boxes:**
   - ✅ Reconnect at sign-in (so it's always available)
   - ✅ Connect using different credentials

7. **Click "Finish"**

8. **Enter credentials when prompted:**
   - Username: `sleszugreen`
   - Password: [the password you set in the setup script]
   - ✅ Check "Remember my credentials"

9. **Click OK**

**Done!** Your UGREEN media now appears as a drive letter (Z:) in File Explorer.

---

### Method 2: Quick Access (No Drive Letter)

**For quick, one-time access without mapping a drive.**

1. **Open File Explorer** (Windows Key + E)

2. **In the address bar**, type:
   ```
   \\192.168.40.60
   ```
   Press Enter

3. **Enter credentials when prompted:**
   - Username: `sleszugreen`
   - Password: [the password you set]

4. **You'll see all available shares:**
   - Movies918 (998 GB of movies)
   - Series918 (435 GB of TV shows)
   - Media (all media combined)

5. **Double-click any share** to browse

---

## Step 3: Test Your Connection

### From Windows:

1. Open the mapped drive (e.g., Z:)
2. You should see your folders:
   - **Movies918**: 2018, 2022, 2023 folders
   - **Series918**: TVshows918 folder

### Try playing a video:
- Navigate to any movie/show
- Double-click to play (if you have VLC, Windows Media Player, etc.)
- It should stream directly from the UGREEN!

---

## Available Shares

| Share Name | Path | Size | Content |
|------------|------|------|---------|
| **Movies918** | `\\192.168.40.60\Movies918` | 998 GB | Movies from 918 NAS |
| **Series918** | `\\192.168.40.60\Series918` | 435 GB | TV shows from 918 NAS |
| **Media** | `\\192.168.40.60\Media` | 1.43 TB | All media combined |

---

## Mapping Multiple Drives

You can map each share to a different drive letter:

- **Z:** → `\\192.168.40.60\Movies918`
- **Y:** → `\\192.168.40.60\Series918`
- **X:** → `\\192.168.40.60\Media`

Just repeat the "Map network drive" process for each one!

---

## Troubleshooting

### "Windows cannot access \\192.168.40.60"

**Cause:** Samba not running or firewall blocking

**Fix on UGREEN:**
```bash
# Check Samba status
sudo systemctl status smbd

# Restart Samba if needed
sudo systemctl restart smbd nmbd

# Check firewall
sudo ufw status
```

---

### "The specified network password is incorrect"

**Cause:** Wrong username or password

**Fix:**
1. Username must be exactly: `sleszugreen` (lowercase)
2. Reset password on UGREEN:
   ```bash
   sudo smbpasswd -a sleszugreen
   ```

---

### "You do not have permission to access"

**Cause:** User not added to Samba or wrong permissions

**Fix on UGREEN:**
```bash
# Add user to Samba
sudo smbpasswd -a sleszugreen

# Check share permissions
ls -la /storage/Media/Movies918
ls -la /storage/Media/Series918
```

---

### Slow transfer speeds

**Normal speeds:**
- Gigabit ethernet: 80-120 MB/s
- WiFi (5 GHz): 30-60 MB/s
- WiFi (2.4 GHz): 10-20 MB/s

**Tips for better performance:**
- Use wired ethernet (not WiFi) for both Windows and UGREEN
- Close other network-heavy applications
- Check network switch/router isn't a bottleneck

---

## Advanced: Add to Windows Credentials Manager

**For permanent, automatic authentication:**

1. Open **Control Panel**
2. Go to **User Accounts** → **Credential Manager**
3. Click **Windows Credentials**
4. Click **Add a Windows credential**
5. Fill in:
   - Internet or network address: `192.168.40.60`
   - User name: `sleszugreen`
   - Password: [your Samba password]
6. Click **OK**

Now Windows will automatically authenticate to the UGREEN!

---

## Useful Commands (Windows)

### Test connection from Command Prompt:
```cmd
ping 192.168.40.60
```

### List available shares:
```cmd
net view \\192.168.40.60
```

### Map drive from command line:
```cmd
net use Z: \\192.168.40.60\Movies918 /user:sleszugreen
```

### Disconnect mapped drive:
```cmd
net use Z: /delete
```

---

## What You Get

✅ **Easy access** - Your UGREEN appears as a normal drive in Windows
✅ **Fast streaming** - Play videos directly without downloading
✅ **Always available** - Automatic reconnection at startup
✅ **Secure** - Password-protected access
✅ **Full read/write** - Can add, delete, organize files from Windows

---

## Network Info

- **UGREEN IP:** 192.168.40.60
- **Protocol:** SMB/CIFS (Samba)
- **Ports used:** 139, 445
- **Network:** 192.168.40.x (same subnet required)

---

**Created:** 2025-12-08
**UGREEN Device:** DXP4800+ Proxmox
**Media Content:** 1.43 TB from 918 NAS
