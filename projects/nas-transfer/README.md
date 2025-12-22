# NAS Transfer Scripts - 918 to UGREEN

## Overview
Transfer ~10TB of media from 918 NAS to UGREEN NAS

**Source:** 192.168.40.10 (918 NAS)
**Destination:** UGREEN /storage/Media/

## Directory Mapping

| Source | Size | Destination |
|--------|------|-------------|
| /volume1/Filmy918 | 1.6TB | /storage/Media/Movies918 |
| /volume1/Series918 | 4.8TB | /storage/Media/Series918 |
| /volume2/Filmy 10TB | 3.9TB | /storage/Media/Movies918 |

## Prerequisites (Already Done ✓)
- [x] SSH key authentication set up
- [x] ZFS datasets created on UGREEN
- [x] backup-user has read access on 918

## How to Run

### IMPORTANT: Run from Proxmox Host as ROOT
These scripts MUST be run from the Proxmox host (not the LXC container) because:
- SSH keys are in /root/.ssh/ on the Proxmox host
- ZFS datasets are mounted on the Proxmox host

### Copy scripts to Proxmox host:
```bash
# From the LXC container, copy to Proxmox host
scp -r /home/sleszugreen/nas-transfer root@192.168.40.60:/root/
```

### On Proxmox Host (192.168.40.60):
```bash
# 1. Create logs directory
mkdir -p /root/nas-transfer-logs

# 2. Make scripts executable
chmod +x /root/nas-transfer/*.sh

# 3. Install screen (if not already installed)
apt update && apt install screen -y

# 4. Start first transfer in screen session
screen -S filmy918
/root/nas-transfer/transfer-filmy918.sh

# Detach from screen: Press Ctrl+A then D
# Reattach later: screen -r filmy918
```

## Monitoring Progress

### Check if screen session is running:
```bash
screen -ls
```

### Attach to see live progress:
```bash
screen -r filmy918
```

### Check logs:
```bash
tail -f /root/nas-transfer-logs/filmy918-*.log
```

### Check transfer status from another terminal:
```bash
watch -n 5 'du -sh /storage/Media/Movies918/'
```

## Transfer Order (Recommended)

1. **Filmy918** (1.6TB) - Smallest, good test run
2. **Filmy 10TB** (3.9TB) - Medium size
3. **Series918** (4.8TB) - Largest

## What Each Script Does

- Uses rsync with archive mode (preserves permissions, timestamps)
- Shows progress with human-readable sizes
- Automatically resumes if interrupted (--partial --append-verify)
- Logs everything to dated log files
- Reports success/failure at end

## If Transfer Gets Interrupted

Just re-run the same script! rsync will:
- Skip files that are already completely copied
- Resume partially transferred files
- Verify all data

## After Transfer Complete

1. Verify file counts match
2. Run verification checksums (optional but recommended)
3. Remove backup-user from administrators group on 918
4. Delete SSH key from 918
5. Delete files from 918 (after verification!)
