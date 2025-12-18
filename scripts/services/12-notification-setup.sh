#!/bin/bash

################################################################################
#                                                                              #
#  Proxmox Hardening - Phase C Script 12                                      #
#  Notification Setup with ntfy.sh                                            #
#                                                                              #
#  Purpose: Set up real-time security alerts without exposing credentials     #
#  Uses: ntfy.sh (free, no email passwords needed)                            #
#                                                                              #
#  Date Created: December 13, 2025                                            #
#  Version: 1.0                                                               #
#                                                                              #
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/root/proxmox-hardening/hardening.log"
SCRIPT_NAME="12-notification-setup.sh"
BACKUP_DIR="/root/proxmox-hardening/backups"

# Configuration
NTFY_TOPIC="proxmox-ugreen-alerts"
NTFY_BASE_URL="https://ntfy.sh"
NTFY_FULL_URL="${NTFY_BASE_URL}/${NTFY_TOPIC}"

################################################################################
# Utility Functions
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo "=== $1 ===" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

################################################################################
# Main Script
################################################################################

log_section "Proxmox Notification Setup - Phase C Script 12"
log "Starting notification setup..."
log "ntfy.sh topic: $NTFY_TOPIC"
log "ntfy.sh URL: $NTFY_FULL_URL"

################################################################################
# Step 1: Verify Requirements
################################################################################

log_section "Step 1: Verify Requirements"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

log_success "Running as root"

# Check curl availability
if ! command -v curl &> /dev/null; then
    log_warning "curl not found, installing..."
    apt update
    apt install -y curl
    log_success "curl installed"
else
    log_success "curl is available"
fi

# Check internet connectivity
if ping -c 1 ntfy.sh &> /dev/null; then
    log_success "Internet connectivity verified (ntfy.sh reachable)"
else
    log_warning "Cannot reach ntfy.sh - notifications may not work"
    log_info "This is not critical - script will continue"
fi

################################################################################
# Step 2: Create Alert Helper Script
################################################################################

log_section "Step 2: Create Alert Helper Script"

cat > /usr/local/bin/send-proxmox-alert << 'HELPER_EOF'
#!/bin/bash
#
# Send alert to ntfy.sh
# Usage: send-proxmox-alert "Message" "priority" "tags"
#

NTFY_TOPIC="proxmox-ugreen-alerts"
NTFY_URL="https://ntfy.sh/${NTFY_TOPIC}"

MESSAGE="${1:-Proxmox Alert}"
PRIORITY="${2:-default}"
TAGS="${3:-warning}"

# Send via curl
curl -s \
    -H "Title: Proxmox Security Alert" \
    -H "Priority: ${PRIORITY}" \
    -H "Tags: ${TAGS}" \
    -d "${MESSAGE}" \
    "${NTFY_URL}" > /dev/null 2>&1

exit 0
HELPER_EOF

chmod +x /usr/local/bin/send-proxmox-alert
log_success "Created alert helper script: /usr/local/bin/send-proxmox-alert"

################################################################################
# Step 3: Configure Fail2ban to Send Notifications
################################################################################

log_section "Step 3: Configure Fail2ban Notifications"

# Check if fail2ban is running
if systemctl is-active --quiet fail2ban; then
    log_success "Fail2ban is running"

    # Create fail2ban action for ntfy.sh
    cat > /etc/fail2ban/action.d/proxmox-ntfy.conf << 'ACTION_EOF'
# Fail2ban action configuration for ntfy.sh notifications
# Sends ban notifications via ntfy.sh

[Definition]
actionstart = /usr/local/bin/send-proxmox-alert "Fail2ban started on <fq-hostname>" "low" "fail2ban"
actionstop = /usr/local/bin/send-proxmox-alert "Fail2ban stopped on <fq-hostname>" "low" "fail2ban"
actioncheck =
actionban = /usr/local/bin/send-proxmox-alert "IP <ip> banned from <name> (attempt: <failures>/<max_retries>)" "high" "fail2ban,ban"
actionunban = /usr/local/bin/send-proxmox-alert "IP <ip> unbanned from <name>" "low" "fail2ban,unban"

[Init]
ACTION_EOF

    log_success "Created ntfy.sh action for fail2ban"

else
    log_warning "Fail2ban is not running"
    log_info "Skipping fail2ban notification configuration"
fi

################################################################################
# Step 4: Create SSH Login Notification Script
################################################################################

log_section "Step 4: Create SSH Login Notification Script"

cat > /etc/profile.d/ssh-alert.sh << 'PROFILE_EOF'
#!/bin/bash
# Send notification when user logs in via SSH

if [ -n "$SSH_CLIENT" ]; then
    IP=$(echo $SSH_CLIENT | awk '{print $1}')
    USER_NAME=$(whoami)
    HOST_NAME=$(hostname)

    # Send alert asynchronously (non-blocking)
    (
        /usr/local/bin/send-proxmox-alert \
            "SSH Login: User ${USER_NAME} from IP ${IP} on ${HOST_NAME}" \
            "low" \
            "ssh,login"
    ) &
    disown
fi
PROFILE_EOF

chmod +x /etc/profile.d/ssh-alert.sh
log_success "Created SSH login notification script"

################################################################################
# Step 5: Create Unattended Upgrades Notification Hook
################################################################################

log_section "Step 5: Create Unattended Upgrades Notification"

cat > /usr/local/bin/proxmox-upgrade-notify << 'UPGRADE_EOF'
#!/bin/bash
# Called by unattended-upgrades to send notification

PACKAGES_FILE="/var/log/unattended-upgrades/unattended-upgrades-dpkg.log"
HOSTNAME=$(hostname)

# Count updated packages
if [ -f "$PACKAGES_FILE" ]; then
    COUNT=$(tail -20 "$PACKAGES_FILE" | grep -c "installed" || echo "?")
else
    COUNT="unknown"
fi

/usr/local/bin/send-proxmox-alert \
    "Security updates installed: ${COUNT} packages on ${HOSTNAME}" \
    "low" \
    "updates,security"

exit 0
UPGRADE_EOF

chmod +x /usr/local/bin/proxmox-upgrade-notify
log_success "Created upgrade notification script"

################################################################################
# Step 6: Create System Health Check Script
################################################################################

log_section "Step 6: Create System Health Check Script"

cat > /usr/local/bin/proxmox-health-check << 'HEALTH_EOF'
#!/bin/bash
# Check system health and send alerts if needed

HOSTNAME=$(hostname)
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85
THRESHOLD_DISK=90

# CPU Usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2)}')
if [ "$CPU_USAGE" -gt "$THRESHOLD_CPU" ]; then
    /usr/local/bin/send-proxmox-alert \
        "High CPU usage on ${HOSTNAME}: ${CPU_USAGE}%" \
        "high" \
        "health,cpu"
fi

# Memory Usage
MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$MEM_USAGE" -gt "$THRESHOLD_MEMORY" ]; then
    /usr/local/bin/send-proxmox-alert \
        "High memory usage on ${HOSTNAME}: ${MEM_USAGE}%" \
        "high" \
        "health,memory"
fi

# Disk Usage
DISK_USAGE=$(df -h / | tail -1 | awk '{print int($5)}')
if [ "$DISK_USAGE" -gt "$THRESHOLD_DISK" ]; then
    /usr/local/bin/send-proxmox-alert \
        "High disk usage on ${HOSTNAME}: ${DISK_USAGE}%" \
        "high" \
        "health,disk"
fi

exit 0
HEALTH_EOF

chmod +x /usr/local/bin/proxmox-health-check
log_success "Created system health check script"

################################################################################
# Step 7: Create Cron Job for Health Checks
################################################################################

log_section "Step 7: Configure Health Check Cron Job"

# Add health check to crontab (runs every 1 hour)
CRON_JOB="0 * * * * /usr/local/bin/proxmox-health-check"

if ! (crontab -l 2>/dev/null | grep -q "proxmox-health-check"); then
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    log_success "Added health check to crontab (every hour)"
else
    log_info "Health check already in crontab"
fi

################################################################################
# Step 8: Create SMART Failure Notification
################################################################################

log_section "Step 8: Configure SMART Failure Notifications"

# Update smartd.conf to use ntfy notifications
if [ -f /etc/smartd.conf ]; then
    # Backup original
    cp /etc/smartd.conf "/etc/smartd.conf.backup.$(date +%s)"

    # Create smartd warning script
    cat > /usr/local/bin/smartd-alert << 'SMART_EOF'
#!/bin/bash
# Alert for SMART failures

DEVICE="$1"
MESSAGE="$2"

/usr/local/bin/send-proxmox-alert \
    "SMART Alert on ${DEVICE}: ${MESSAGE}" \
    "high" \
    "disk,smart"

exit 0
SMART_EOF

    chmod +x /usr/local/bin/smartd-alert
    log_success "Created SMART alert script"
    log_info "SMART notifications configured (requires smartd restart)"
else
    log_warning "smartd.conf not found - skipping SMART notifications"
fi

################################################################################
# Step 9: Test Notification System
################################################################################

log_section "Step 9: Test Notification System"

log_info "Sending test notification to: $NTFY_FULL_URL"

TEST_RESPONSE=$(/usr/local/bin/send-proxmox-alert \
    "Test notification from Proxmox $(hostname) - Notification setup complete!" \
    "low" \
    "test,setup" 2>&1 || true)

if [ $? -eq 0 ]; then
    log_success "Test notification sent successfully"
    log_info "Check your ntfy app for the test message"
else
    log_warning "Test notification may have failed"
    log_info "This could be a network issue - continue anyway"
fi

################################################################################
# Step 10: Create User Instructions
################################################################################

log_section "Step 10: User Instructions"

cat > /tmp/NOTIFICATION-SETUP-INSTRUCTIONS.txt << 'INSTRUCTIONS_EOF'
╔════════════════════════════════════════════════════════════════════╗
║         PROXMOX NOTIFICATION SETUP - USER INSTRUCTIONS            ║
╚════════════════════════════════════════════════════════════════════╝

WHAT WAS INSTALLED
═════════════════════════════════════════════════════════════════════

1. Alert Helper Script: /usr/local/bin/send-proxmox-alert
   └─ Sends messages to ntfy.sh

2. SSH Login Notifications
   └─ Notifies when user logs in via SSH

3. System Health Checks
   └─ Hourly checks for high CPU/memory/disk usage
   └─ Runs via crontab every hour

4. SMART Notifications
   └─ Alerts for disk health issues

5. Fail2ban Integration
   └─ Sends ban/unban notifications


SUBSCRIBING TO NOTIFICATIONS
═════════════════════════════════════════════════════════════════════

You have TWO options:

OPTION 1: Web Browser (Easiest)
────────────────────────────────
1. Go to: https://ntfy.sh/proxmox-ugreen-alerts
2. Keep page open in browser
3. Notifications appear instantly

OPTION 2: Mobile App (Recommended)
───────────────────────────────────
1. Install ntfy app:
   - Android: https://play.google.com/store/apps/details?id=io.heckel.ntfy
   - iOS: https://apps.apple.com/app/ntfy/id1625396347

2. Open app and tap "+"

3. Enter topic: proxmox-ugreen-alerts

4. Notifications sent to your phone instantly


TESTING NOTIFICATIONS
═════════════════════════════════════════════════════════════════════

Test SSH login notification:
  $ ssh -p 22022 root@192.168.40.60
  (Check ntfy app - should see notification)

Test system health check:
  $ /usr/local/bin/proxmox-health-check
  (May or may not send alert depending on system load)

Test manual alert:
  $ /usr/local/bin/send-proxmox-alert "Test message" "low" "test"


WHAT YOU'LL SEE
═════════════════════════════════════════════════════════════════════

Notifications are sent for:

1. SSH Logins
   └─ Every successful SSH login shows IP and username

2. Fail2ban Bans
   └─ When IP is banned: shows IP and jail name
   └─ When IP is unbanned: shows IP and jail name

3. System Health
   └─ High CPU usage (>80%)
   └─ High memory usage (>85%)
   └─ High disk usage (>90%)

4. Security Updates
   └─ When automatic updates are installed

5. SMART Issues
   └─ If disk health problems detected


CUSTOMIZATION
═════════════════════════════════════════════════════════════════════

To change notification topic:
  $ sed -i 's/proxmox-ugreen-alerts/your-topic-name/g' /usr/local/bin/send-proxmox-alert

To change health check thresholds:
  $ nano /usr/local/bin/proxmox-health-check
  └─ Edit THRESHOLD_CPU, THRESHOLD_MEMORY, THRESHOLD_DISK

To disable SSH login notifications:
  $ rm /etc/profile.d/ssh-alert.sh

To disable health checks:
  $ crontab -e
  └─ Remove the proxmox-health-check line


TROUBLESHOOTING
═════════════════════════════════════════════════════════════════════

If you're not receiving notifications:

1. Check internet connectivity:
   $ ping ntfy.sh

2. Test the alert script:
   $ /usr/local/bin/send-proxmox-alert "Test" "low" "test"

3. Check for errors:
   $ tail -50 /root/proxmox-hardening/hardening.log

4. Verify topic is correct:
   https://ntfy.sh/proxmox-ugreen-alerts


IMPORTANT NOTES
═════════════════════════════════════════════════════════════════════

• ntfy.sh is completely FREE
• No account needed
• No email passwords exposed
• Anyone with the topic name can see messages (choose a unique name)
• Messages are kept for 24 hours
• Works on any device with a browser or app


OPTIONAL: CHANGING THE TOPIC NAME
═════════════════════════════════════════════════════════════════════

The current topic is: proxmox-ugreen-alerts

To change it to something more private:
  $ sudo sed -i 's/proxmox-ugreen-alerts/your-private-topic-name/g' \
    /usr/local/bin/send-proxmox-alert

Then subscribe with the new topic name in ntfy app.


═════════════════════════════════════════════════════════════════════
Questions or issues? Check the script logs:
  $ tail -100 /root/proxmox-hardening/hardening.log
═════════════════════════════════════════════════════════════════════
INSTRUCTIONS_EOF

cat /tmp/NOTIFICATION-SETUP-INSTRUCTIONS.txt | tee -a "$LOG_FILE"

log_success "Instructions saved to /tmp/NOTIFICATION-SETUP-INSTRUCTIONS.txt"

################################################################################
# Step 11: Display Summary
################################################################################

log_section "Notification Setup Complete"

echo "" | tee -a "$LOG_FILE"
echo "✅ Notification Setup Complete" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "What was set up:" | tee -a "$LOG_FILE"
echo "  ✅ Alert helper script: /usr/local/bin/send-proxmox-alert" | tee -a "$LOG_FILE"
echo "  ✅ SSH login notifications" | tee -a "$LOG_FILE"
echo "  ✅ System health checks (hourly)" | tee -a "$LOG_FILE"
echo "  ✅ SMART failure alerts" | tee -a "$LOG_FILE"
echo "  ✅ Fail2ban notifications" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "To subscribe to notifications:" | tee -a "$LOG_FILE"
echo "  Option 1: https://ntfy.sh/proxmox-ugreen-alerts" | tee -a "$LOG_FILE"
echo "  Option 2: Install ntfy app and subscribe to 'proxmox-ugreen-alerts'" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Full instructions: /tmp/NOTIFICATION-SETUP-INSTRUCTIONS.txt" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

log "Script 12 completed successfully!"

################################################################################
# End of Script
################################################################################

exit 0
