# LXC 102 Scripts Mount - Implementation Commands

**⚠️ CRITICAL:** Follow these steps EXACTLY. This is production infrastructure.

---

## Overview

You will:
1. Create the directory on the 2TB NVMe
2. Set proper permissions
3. Edit the LXC config file
4. Restart the container
5. Verify the mount works

**Total time:** ~5 minutes

---

## Step-by-Step Instructions

### STEP 1: Create the Directory and Set Ownership

**Location:** ON PROXMOX HOST

Run these commands:
```bash
# Create the directory
sudo mkdir -p /nvme2tb/lxc102scripts

# Set ownership to sleszugreen (so I can write scripts)
sudo chown sleszugreen:sleszugreen /nvme2tb/lxc102scripts

# Set permissions (755 = owner read/write/execute, group & others read/execute)
sudo chmod 755 /nvme2tb/lxc102scripts

# Verify the directory was created with correct ownership
ls -la /nvme2tb/ | grep lxc102scripts
```

**Expected output:**
```
drwxr-xr-x sleszugreen sleszugreen 4096 Dec 20 ... lxc102scripts
```

---

### STEP 2: Backup Current LXC Config

**Location:** ON PROXMOX HOST

```bash
# Create a backup with timestamp
sudo cp /etc/pve/lxc/102.conf /etc/pve/lxc/102.conf.backup-$(date +%Y%m%d-%H%M%S)

# Verify backup was created
ls -la /etc/pve/lxc/102.conf*
```

---

### STEP 3: Edit the LXC Config File

**Location:** ON PROXMOX HOST

Add the new mount point to the config. You have two options:

#### Option A: Using nano (easier)
```bash
sudo nano /etc/pve/lxc/102.conf
```

Then:
1. Go to the end of the file (Ctrl+End)
2. Add this line on a new line:
   ```
   mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts
   ```
3. Save (Ctrl+X, then Y, then Enter)

#### Option B: Using sed (one-liner, faster)
```bash
sudo sed -i '/^unused0:/a mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts' /etc/pve/lxc/102.conf
```

#### Option C: Using echo (safest one-liner)
```bash
echo "mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts" | sudo tee -a /etc/pve/lxc/102.conf
```

---

### STEP 4: Verify the Config Change

**Location:** ON PROXMOX HOST

```bash
# Display the config file to verify the change
sudo cat /etc/pve/lxc/102.conf
```

**You should see at the end:**
```
mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts
```

---

### STEP 5: Restart the Container

**Location:** ON PROXMOX HOST

```bash
# Stop the container gracefully
sudo pct shutdown 102 --timeout 60

# Wait 5 seconds for shutdown
sleep 5

# Start the container
sudo pct start 102

# Check the status
sudo pct status 102
```

**Expected output:**
```
status: running
```

---

### STEP 6: Verify the Mount Works

**Location:** AFTER CONTAINER RESTARTS - FROM INSIDE THE CONTAINER

Once the container restarts, log back in and run:

```bash
# List the mounted directories
mount | grep lxc102scripts

# Check the /mnt directory
ls -la /mnt/lxc102scripts

# Try creating a test file
touch /mnt/lxc102scripts/test-file.txt

# List it to confirm
ls -la /mnt/lxc102scripts/

# Remove the test file
rm /mnt/lxc102scripts/test-file.txt
```

**Expected output:**
```
/nvme2tb/lxc102scripts on /mnt/lxc102scripts type none (rw,relatime,bind)
```

---

## Verification Checklist

After completing all steps, verify:

- [ ] Directory `/nvme2tb/lxc102scripts/` exists on Proxmox host
- [ ] Directory is owned by `sleszugreen:sleszugreen`
- [ ] Config file has `mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts` line
- [ ] Container starts successfully without errors
- [ ] `/mnt/lxc102scripts/` is accessible from inside container
- [ ] Can create files in `/mnt/lxc102scripts/` from container
- [ ] Files created in container appear on Proxmox host at `/nvme2tb/lxc102scripts/`

---

## If Something Goes Wrong

### Container Won't Start

Check for syntax errors:
```bash
# Validate the config
sudo pct config 102 | grep -A 2 "mp1:"

# Look at the last few lines of the config
sudo tail -5 /etc/pve/lxc/102.conf
```

If there's an error, remove the problematic line:
```bash
# Restore from backup
sudo cp /etc/pve/lxc/102.conf.backup-* /etc/pve/lxc/102.conf

# Start the container
sudo pct start 102
```

### Mount Didn't Work

Verify the source directory exists:
```bash
ls -la /nvme2tb/lxc102scripts/
```

If it doesn't exist:
```bash
sudo mkdir -p /nvme2tb/lxc102scripts
sudo chown sleszugreen:sleszugreen /nvme2tb/lxc102scripts
sudo chmod 755 /nvme2tb/lxc102scripts
sudo pct shutdown 102 --timeout 60
sleep 5
sudo pct start 102
```

---

## Quick Reference

| Item | Path |
|------|------|
| **On Proxmox Host** | `/nvme2tb/lxc102scripts/` |
| **In Container** | `/mnt/lxc102scripts/` |
| **Config File** | `/etc/pve/lxc/102.conf` |
| **Config Backup** | `/etc/pve/lxc/102.conf.backup-*` |
| **Ownership** | `sleszugreen:sleszugreen` |
| **Permissions** | `755` (rwxr-xr-x) |

---

## After Implementation

- Scripts placed in `/nvme2tb/lxc102scripts/` on the Proxmox host will be immediately accessible at `/mnt/lxc102scripts/` inside the container
- I can create, edit, and delete scripts from inside the container
- You can execute scripts from the Proxmox host
- The mount persists across container restarts
