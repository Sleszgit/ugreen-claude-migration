# 918 to UGREEN NAS Transfer - Quick Start Guide

## What Will Be Copied

**FROM 918 NAS → TO UGREEN NAS:**
```
/volume1/Filmy918/2018/         → /storage/Media/Movies918/2018/
/volume1/Filmy918/2022/         → /storage/Media/Movies918/2022/
/volume1/Filmy918/2023/         → /storage/Media/Movies918/2023/
/volume1/Series918/TVshows918/  → /storage/Media/Series918/TVshows918/
```

✅ **GUARANTEED:** 918 NAS will NOT be modified (read-only operation)

---

## Step 1: Prepare on Proxmox Host

**You are currently in LXC 102. These commands must run on the Proxmox host (root@ugreen).**

If you see `root@ugreen:~#` prompt, you're in the right place!

```bash
# Create logs directory
mkdir -p /root/nas-transfer-logs

# Copy scripts from LXC to Proxmox host (if needed)
# Skip this if you're already seeing the scripts in /root/

# Make scripts executable
chmod +x /home/sleszugreen/nas-transfer/*.sh
```

---

## Step 2: Install Screen (for background running)

```bash
apt update && apt install screen -y
```

---

## Step 3: Start First Transfer (Movies)

```bash
# Start screen session
screen -S movies

# Run the movies transfer script
/home/sleszugreen/nas-transfer/transfer-movies-2018-2022-2023.sh

# Detach from screen (transfer continues in background)
# Press: Ctrl+A then D
```

---

## Step 4: Start Second Transfer (TV Shows)

```bash
# Start another screen session
screen -S tvshows

# Run TV shows transfer script
/home/sleszugreen/nas-transfer/transfer-tvshows918.sh

# Detach from screen
# Press: Ctrl+A then D
```

---

## Monitoring Progress

### See all screen sessions:
```bash
screen -ls
```

### Attach to see live transfer:
```bash
screen -r movies      # For movies transfer
screen -r tvshows     # For TV shows transfer
```

### Check logs:
```bash
# Latest movies log
tail -f /root/nas-transfer-logs/movies-*.log

# Latest tvshows log
tail -f /root/nas-transfer-logs/tvshows918-*.log
```

### Check disk usage (from another terminal):
```bash
watch -n 5 'du -sh /storage/Media/Movies918/* /storage/Media/Series918/*'
```

---

## If Transfer Gets Interrupted

**Just re-run the same script!** rsync will:
- Skip files already copied
- Resume partial files
- Verify everything

---

## Estimated Transfer Times

*Depends on network speed (probably ~100MB/s on gigabit)*

- Movies (2018+2022+2023): Unknown size - check with script
- TVshows918: Unknown size - check with script

**The transfer will show progress and ETA while running.**

---

## After Transfer Complete

1. Verify file counts match source
2. Compare sizes
3. (Optional) Run checksum verification
4. Once confirmed, you can delete from 918

---

## Safety Notes

✅ Scripts use rsync in COPY mode only
✅ NO --delete flag (won't remove anything)
✅ NO --remove-source-files (originals stay on 918)
✅ backup-user has read-only access
✅ Can be stopped and resumed anytime (Ctrl+C in screen, then re-run)

**Your 918 NAS will remain completely untouched!**
