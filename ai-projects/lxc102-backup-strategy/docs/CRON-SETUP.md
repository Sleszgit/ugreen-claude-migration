# LXC102 Backup Automation - Cron Setup

**Created:** 2026-01-01
**Purpose:** Configure automated daily backups
**Owner:** Claude (Strategic Lead)

---

## Overview

Two automated backup jobs need to be scheduled:

1. **Daily Vzdump (Primary)** - 2 AM on Proxmox host
   - Runs as: root on UGREEN Proxmox host (192.168.40.60)
   - Command: `/mnt/lxc102scripts/backup-lxc102-vzdump.sh`
   - Frequency: Daily
   - Logs to: `/var/log/lxc102-vzdump-backup.log`

2. **Daily Rsync (Secondary)** - 3 AM in LXC102 container
   - Runs as: sleszugreen in LXC102 container
   - Command: `/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh`
   - Frequency: Daily
   - Logs to: `~/logs/lxc102-rsync-backup.log`

---

## Cron Configuration

### Job 1: Vzdump Backup (Proxmox Host)

**Where:** Proxmox host (192.168.40.60) - edit crontab as root
**When:** Daily at 2:00 AM
**Command:** `/mnt/lxc102scripts/backup-lxc102-vzdump.sh`

#### Setup Steps

```bash
# 1. Access Proxmox host as root
ssh root@192.168.40.60
# OR from container:
ssh sshadmin@192.168.40.40
# Then: ssh root@192.168.40.60

# 2. Edit root crontab
sudo crontab -e

# 3. Add the following line to the crontab:
0 2 * * * /mnt/lxc102scripts/backup-lxc102-vzdump.sh >> /var/log/lxc102-vzdump-backup.log 2>&1

# 4. Verify the job was added
sudo crontab -l | grep backup-lxc102-vzdump

# 5. Verify the script can be executed
sudo /mnt/lxc102scripts/backup-lxc102-vzdump.sh --help 2>&1 | head -5
```

**Crontab Entry:**
```
# LXC102 Daily Vzdump Backup (Primary)
# Runs daily at 2:00 AM - Creates full container backup
# Destination: Homelab NFS mount (/mnt/homelab-backups/lxc102-vzdump/)
0 2 * * * /mnt/lxc102scripts/backup-lxc102-vzdump.sh >> /var/log/lxc102-vzdump-backup.log 2>&1
```

**Cron Syntax Explanation:**
```
0     2     *     *     *     Command to run
|     |     |     |     |
|     |     |     |     └─ Day of week (0=Sun, 6=Sat) - * = every day
|     |     |     └─ Month (1-12) - * = every month
|     |     └─ Day of month (1-31) - * = every day
|     └─ Hour (0-23) - 2 = 2:00 AM
└─ Minute (0-59) - 0 = :00
```

---

### Job 2: Rsync Backup (LXC102 Container)

**Where:** LXC102 container - edit crontab for sleszugreen user
**When:** Daily at 3:00 AM
**Command:** `/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh`

#### Setup Steps

```bash
# 1. Inside LXC102 container as sleszugreen
# (Already logged in or use SSH)
ssh sleszugreen@192.168.40.60

# 2. Edit user crontab (not root)
crontab -e

# 3. Add the following line:
0 3 * * * /home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh >> ~/logs/lxc102-rsync-backup.log 2>&1

# 4. Verify the job was added
crontab -l | grep backup-lxc102-rsync

# 5. Verify the script can be executed
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh --help 2>&1 | head -5
```

**Crontab Entry:**
```
# LXC102 Daily Rsync Backup (Secondary)
# Runs daily at 3:00 AM - Incremental file backup to UGREEN NAS
# Destination: /storage/Media/backups/lxc102-rsync/
0 3 * * * /home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh >> ~/logs/lxc102-rsync-backup.log 2>&1
```

**Cron Syntax Explanation:** (Same as above)
- 3 = 3:00 AM
- All other values same as vzdump

---

## Complete Crontab Files

### Proxmox Host Root Crontab

**File:** Edit with `sudo crontab -e` as root on Proxmox host

```crontab
# LXC102 Backup Automation
# ============================================================

# Primary Backup: Full Container Backup → Homelab
# Runs daily at 2:00 AM (off-peak)
# Takes ~10-30 minutes depending on size
# Destination: Homelab NFS mount
0 2 * * * /mnt/lxc102scripts/backup-lxc102-vzdump.sh >> /var/log/lxc102-vzdump-backup.log 2>&1

# Optional: Email on job failure (uncomment if you have mail configured)
# MAILTO=admin@example.com
# 0 2 * * * /mnt/lxc102scripts/backup-lxc102-vzdump.sh >> /var/log/lxc102-vzdump-backup.log 2>&1 || echo "Vzdump backup failed" | mail -s "Backup Alert" $MAILTO
```

### LXC102 User Crontab

**File:** Edit with `crontab -e` as sleszugreen user inside container

```crontab
# LXC102 Rsync Backup Automation
# ============================================================

# Secondary Backup: Incremental Files → UGREEN NAS
# Runs daily at 3:00 AM (after work, off-peak)
# Takes ~5-15 minutes depending on changes
# Destination: /storage/Media/backups/lxc102-rsync/
0 3 * * * /home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh >> ~/logs/lxc102-rsync-backup.log 2>&1

# Optional: Weekly verification (run at 4 AM on Sunday)
# 0 4 * * 0 /home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/restore-lxc102.sh list-rsync >> ~/logs/lxc102-rsync-backup.log 2>&1
```

---

## Verification Procedures

### Verify Cron Jobs Are Installed

```bash
# Check Proxmox host crontab
sudo crontab -l | grep backup

# Check container user crontab
crontab -l | grep backup

# Both should show the respective backup commands
```

### Verify Cron Jobs Execute

```bash
# Wait for scheduled time (2 AM for vzdump, 3 AM for rsync)
# OR run manually to test:

# Test vzdump (on Proxmox host)
sudo /mnt/lxc102scripts/backup-lxc102-vzdump.sh

# Test rsync (in container)
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh

# Check log files for success messages
sudo tail -50 /var/log/lxc102-vzdump-backup.log
tail -50 ~/logs/lxc102-rsync-backup.log
```

### Monitor Cron Execution

```bash
# Check system cron logs
sudo journalctl -u cron --since "2 hours ago"

# OR check syslog
sudo grep CRON /var/log/syslog | grep backup

# Should show entries like:
# CRON[12345]: (root) CMD (/mnt/lxc102scripts/backup-lxc102-vzdump.sh ...)
```

---

## Schedule & Timing

### Backup Window

```
Time     Event                    Host              Duration  Status
────────────────────────────────────────────────────────────────────
22:00    Night work ends          LXC102            -         -
23:00    Container quiet period   LXC102            1h        Monitor
02:00    Vzdump starts            Proxmox host      10-30m    Transfer to Homelab
03:00    Rsync starts             LXC102            5-15m     Files to NAS
04:00    Both backups done        -                 -         Verify logs
08:00    Work resumes             LXC102            -         -
```

### Daily Backup Timeline

- **2:00 AM:** Vzdump backup starts (off-peak, no work)
  - LXC102 container is snapshot-backed
  - Backup transferred to Homelab
  - Takes: 10-30 minutes

- **2:30+ AM:** Vzdump completes and transfers
  - Container returns to normal
  - Old backups cleaned up

- **3:00 AM:** Rsync backup starts
  - Incremental sync to UGREEN NAS
  - Only changed files transferred
  - Takes: 5-15 minutes

- **3:30 AM:** Rsync completes
  - Old snapshots cleaned up
  - Logs updated

**Result:** By 4 AM, both backups are complete and LXC102 has full redundancy

---

## Troubleshooting

### If Cron Job Doesn't Run

```bash
# Check if cron service is active
sudo systemctl status cron

# If not running, start it
sudo systemctl start cron
sudo systemctl enable cron

# Verify cron daemon is listening
sudo systemctl is-active cron

# Check system logs for cron errors
sudo journalctl -u cron -n 50

# Check if crontab is installed correctly
sudo crontab -l   # Proxmox host
crontab -l        # LXC102 container
```

### If Backup Fails

```bash
# 1. Check the log file
tail -100 /var/log/lxc102-vzdump-backup.log
tail -100 ~/logs/lxc102-rsync-backup.log

# 2. Run script manually to see detailed errors
sudo /mnt/lxc102scripts/backup-lxc102-vzdump.sh
/home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/backup-lxc102-rsync.sh

# 3. Check prerequisites
# For vzdump:
sudo pct status 102                          # Container exists?
ssh backup-user@192.168.40.40 "echo OK"     # SSH works?

# For rsync:
ls -la /storage/Media/                       # NAS mounted?
touch /storage/Media/test.txt 2>/dev/null  # Write permission?

# 4. If SSH issue, test keys
ssh-keyscan 192.168.40.40 >> ~/.ssh/known_hosts  # Add host key
ssh -v backup-user@192.168.40.40 "echo test"     # Test with verbose
```

### If Disk Space Low

```bash
# Check backup sizes
sudo du -sh /var/lib/vz/dump/*
du -sh /storage/Media/backups/lxc102-rsync/*

# Check available space
sudo df -h /var/lib/vz/dump/
df -h /storage/Media/

# If low, reduce retention:
# Edit scripts to keep fewer backups
# Default: vzdump=10, rsync=7
```

---

## Monitoring

### Manual Backup Status Check

```bash
# Scheduled backups complete
log_status() {
  echo "=== Vzdump Backup Status ==="
  ssh backup-user@192.168.40.40 \
    "ls -lh /mnt/homelab-backups/lxc102-vzdump/ | tail -5"

  echo ""
  echo "=== Rsync Snapshots ==="
  ls -lh /storage/Media/backups/lxc102-rsync/ | tail -5

  echo ""
  echo "=== Log Files ==="
  echo "Vzdump log:"
  sudo tail -10 /var/log/lxc102-vzdump-backup.log
  echo ""
  echo "Rsync log:"
  tail -10 ~/logs/lxc102-rsync-backup.log
}

# Run manually
log_status
```

### Automated Monitoring (Optional)

Add a weekly check:

```crontab
# Optional: Weekly backup verification (runs at 4 AM on Sunday)
0 4 * * 0 /home/sleszugreen/ai-projects/lxc102-backup-strategy/scripts/restore-lxc102.sh list-rsync >> ~/logs/lxc102-backup-verify.log 2>&1
0 4 * * 0 ssh backup-user@192.168.40.40 "ls /mnt/homelab-backups/lxc102-vzdump/" >> ~/logs/lxc102-backup-verify.log 2>&1
```

---

## Status Checklist

- [ ] Vzdump cron job installed on Proxmox host
- [ ] Rsync cron job installed in LXC102 container
- [ ] Both cron jobs verified with `crontab -l`
- [ ] Test runs completed successfully
- [ ] Log files created and populated
- [ ] Monitoring procedure documented
- [ ] Backup schedule documented in calendar/wiki
- [ ] Team notified of new backup schedule

---

**Owner:** Claude Code
**Last Updated:** 2026-01-01
**Next Review:** After first scheduled backup execution
