# LXC 102 Container Stability Monitoring

**Date Created:** 2026-01-01
**Purpose:** Track container health and detect crashes/restarts following the Session 74 fix
**Location:** LXC 102 (ugreen-ai-terminal)

---

## Overview

Following the LXC 102 crash fix (Session 74), this monitoring system tracks container stability and detects any:
- Unexpected restarts or crashes
- Memory pressure issues
- System resource constraints
- Service failures
- SSH connectivity problems

The monitoring runs **every 5 minutes** via cron and logs all data for review.

---

## Setup

### Scripts Installed

| Script | Location | Purpose |
|--------|----------|---------|
| **Monitor** | `~/scripts/lxc102-monitor.sh` | Core monitoring daemon (runs via cron) |
| **Viewer** | `~/scripts/lxc102-monitor-view.sh` | Dashboard to view monitoring data |

### Log Directory

```
~/logs/lxc102-monitor/
├── monitor-2026-01-01.log      # Daily logs (one per date)
├── alerts-2026-01-01.log       # Alerts and warnings
├── status-current.json         # Latest status (JSON format)
└── .previous_uptime            # Internal state tracking
```

### Cron Job

```
*/5 * * * * /home/sleszugreen/scripts/lxc102-monitor.sh
```

**Frequency:** Every 5 minutes
**Run as:** Your user account (sleszugreen)
**Total daily checks:** 288 checks/day (24 hours × 12 per hour)

---

## Usage

### View Current Status

```bash
lxc102-monitor-view.sh status
```

Shows:
- Current uptime
- Memory usage
- Load average
- Process count
- Disk usage
- SSH port status
- Container state
- Restart detection

### View Recent Logs

```bash
lxc102-monitor-view.sh logs
```

Shows the last 30 monitoring entries with timestamps.

### View Alerts

```bash
lxc102-monitor-view.sh alerts
```

Shows all alerts and warnings recorded for today.

### View Summary

```bash
lxc102-monitor-view.sh summary
```

Shows:
- Total checks performed
- Number of restarts detected
- Number of alerts
- Overall health assessment
- Monitoring duration

### View Everything

```bash
lxc102-monitor-view.sh all
```

Shows all of the above (default).

### Show Help

```bash
lxc102-monitor-view.sh help
```

---

## What's Being Monitored

### Container Status
- **Uptime:** How long container has been running
- **Container State:** Running, degraded, or error
- **Restart Detection:** Detects unexpected restarts

### System Resources
- **Memory Usage:** Current memory consumption + percentage
- **Load Average:** 1-minute, 5-minute, 15-minute averages
- **Process Count:** Number of running processes
- **Disk Usage:** Root filesystem usage percentage

### Service Health
- **Failed Units:** Count of failed systemd units
- **SSH Port:** Whether SSH port 22 is responding
- **System Errors:** Last error message from journal

### Alerts Triggered On

| Condition | Alert |
|-----------|-------|
| Container restart | `CONTAINER RESTART DETECTED` |
| Memory > 85% | `HIGH MEMORY USAGE` |
| Failed systemd units > 0 | `FAILED SYSTEMD UNITS` |

---

## Understanding the Data

### JSON Status Format

Example `status-current.json`:

```json
{
  "timestamp": "2026-01-01 09:19:47",
  "uptime": "09:19:47 up 6 min",
  "memory_used": "316Mi / 4.0Gi",
  "memory_percent": 7.7,
  "load_average": "0.47 0.31 0.19",
  "processes": 33,
  "disk_usage": "1.9G / 20G (10%)",
  "ssh_status": "CLOSED",
  "container_state": "running",
  "failed_units": 0,
  "restart_detected": "NO"
}
```

### Log Format

```
[2026-01-01 09:19:47]
  Uptime: 09:19:47 up 6 min
  Memory: 316Mi / 4.0Gi (7.7%)
  Load Average: 0.47 0.31 0.19
  Processes: 33
  Disk: 1.9G / 20G (10%)
  SSH Port: CLOSED
  Container State: running
  Failed Units: 0
  Restart Detected: NO
```

---

## Interpreting Results

### ✅ Healthy Container

```
Container State: running
Failed Units: 0
Restart Detected: NO
Memory < 80%
SSH Port: OPEN (when SSH is active)
```

### ⚠️ Minor Issues

```
Memory: 85-95%          → Monitor memory usage
Failed Units: 1-2       → Check which units failed
SSH Port: CLOSED        → Normal if no SSH session
```

### ❌ Serious Issues

```
Restart Detected: YES   → Container crashed and restarted
Failed Units: > 2       → Multiple services down
Memory: > 95%           → Critical memory pressure
```

---

## Manual Testing

### Test Restart Detection

```bash
# The script saves the previous uptime
# Next time it runs, if uptime is less, it detects a restart

# Test by checking:
cat ~/logs/lxc102-monitor/.previous_uptime
```

### Run Monitoring Script Manually

```bash
# Run once immediately
/home/sleszugreen/scripts/lxc102-monitor.sh

# Check the results
lxc102-monitor-view.sh status
```

### Check Cron Job Status

```bash
# View cron jobs
crontab -l | grep lxc102

# Check cron logs (system-dependent)
sudo grep CRON /var/log/syslog | tail -10
```

---

## Troubleshooting

### No logs appearing

1. Check cron is running:
   ```bash
   crontab -l | grep lxc102
   ```

2. Run script manually:
   ```bash
   /home/sleszugreen/scripts/lxc102-monitor.sh
   ```

3. Check log directory exists:
   ```bash
   ls -la ~/logs/lxc102-monitor/
   ```

### "No status data available"

The monitoring script hasn't run yet. Wait 5 minutes for the first cron execution, or run manually:

```bash
/home/sleszugreen/scripts/lxc102-monitor.sh
```

### SSH Port shows CLOSED

This is normal if no SSH session is active. The monitoring script checks if port 22 is bound, not if SSH service is running.

### High Memory Usage Alerts

Check what's using memory:

```bash
ps aux --sort=-%mem | head -10
```

---

## Long-Term Monitoring

### Daily Review

Every morning, run:

```bash
lxc102-monitor-view.sh summary
```

This shows:
- Total checks for the day
- Any restarts detected
- Health assessment

### Weekly Analysis

```bash
# See all logs for the week
ls -lh ~/logs/lxc102-monitor/monitor-*.log

# Count total restarts across week
grep -r "Restart Detected: YES" ~/logs/lxc102-monitor/
```

### Archiving Old Logs

After 30 days, compress old log files:

```bash
# Compress logs older than 30 days
find ~/logs/lxc102-monitor/ -name "monitor-*.log" -mtime +30 -exec gzip {} \;

# View compressed logs
zcat ~/logs/lxc102-monitor/monitor-2025-12-01.log.gz
```

---

## Expected Baseline (Post-Fix)

Following the Session 74 fix, expect:

| Metric | Expected |
|--------|----------|
| **Uptime** | Continuously increases (days/weeks) |
| **Restarts** | 0 unless host reboots |
| **Memory** | 5-15% under normal load |
| **Failed Units** | 0 |
| **Alerts** | None (unless resource issues) |

---

## Validation Against Session 74 Fix

The monitoring system validates that the following configuration is working:

```
/etc/pve/lxc/102.conf (Proxmox host):
  onboot: 1                    ✓ Auto-start enabled
  startup: order=2,up=60       ✓ Startup sequencing working
```

**Evidence:**
- Container stays running without unexpected restarts
- SSH sessions don't crash the container
- Container persists across multiple monitoring cycles

---

## Related Documentation

- **Session 74:** `SESSION-74-LXC102-CRASH-FIX-APPLIED.md` - Initial fix details
- **Session 73:** `SESSION-73-LXC102-CRASH-DIAGNOSIS.md` - Root cause analysis
- **CLAUDE.md:** System configuration and defaults

---

## Quick Reference

```bash
# View status
lxc102-monitor-view.sh status

# View alerts only
lxc102-monitor-view.sh alerts

# Full dashboard
lxc102-monitor-view.sh all

# Check cron job
crontab -l | grep lxc102

# Run monitoring now
/home/sleszugreen/scripts/lxc102-monitor.sh

# View today's logs
cat ~/logs/lxc102-monitor/monitor-$(date +%Y-%m-%d).log
```

---

**Last Updated:** 2026-01-01
**Monitoring Started:** 2026-01-01
**Status:** Active and running
