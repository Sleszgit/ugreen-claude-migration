#!/bin/bash

################################################################################
# LXC 102 Container Stability Monitor
#
# Purpose: Track container health and detect crashes/restarts
# Location: ~/scripts/lxc102-monitor.sh
# Logs: ~/logs/lxc102-monitor/
#
# Run via cron: */5 * * * * /home/sleszugreen/scripts/lxc102-monitor.sh
################################################################################

LOG_DIR="$HOME/logs/lxc102-monitor"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_ONLY=$(date '+%Y-%m-%d')
LOG_FILE="$LOG_DIR/monitor-$DATE_ONLY.log"
STATUS_FILE="$LOG_DIR/status-current.json"
ALERT_FILE="$LOG_DIR/alerts-$DATE_ONLY.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

################################################################################
# DATA COLLECTION FUNCTIONS
################################################################################

get_uptime() {
    uptime | awk '{print $1, $2, $3, $4}' | sed 's/,//'
}

get_uptime_seconds() {
    # Convert uptime to seconds for comparison
    local uptime_str=$(uptime -p 2>/dev/null || uptime)

    if [[ $uptime_str =~ ([0-9]+)\ day ]]; then
        echo $(( ${BASH_REMATCH[1]} * 86400 ))
    elif [[ $uptime_str =~ ([0-9]+):([0-9]+) ]]; then
        echo $(( ${BASH_REMATCH[1]} * 3600 + ${BASH_REMATCH[2]} * 60 ))
    else
        echo 0
    fi
}

get_memory_usage() {
    free -h | grep Mem | awk '{print $3 " / " $2}'
}

get_memory_percent() {
    free | awk 'NR==2 {printf "%.1f", ($3/$2)*100}'
}

get_load_average() {
    cat /proc/loadavg | awk '{print $1 " " $2 " " $3}'
}

get_process_count() {
    ps aux | wc -l
}

get_disk_usage() {
    df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}'
}

get_failed_units() {
    systemctl list-units --failed --no-pager --no-legend 2>/dev/null | wc -l
}

get_ssh_status() {
    if netstat -tuln 2>/dev/null | grep -q ":22 "; then
        echo "OPEN"
    else
        echo "CLOSED"
    fi
}

get_last_error() {
    journalctl -n 1 --no-pager 2>/dev/null | grep -iE "error|failed|crash|emergency" | cut -c1-80
}

get_boot_time() {
    systemctl show -p SystemState 2>/dev/null || echo "unknown"
}

get_container_state() {
    systemctl is-system-running 2>/dev/null || echo "unknown"
}

################################################################################
# CRASH DETECTION
################################################################################

detect_restart() {
    local prev_uptime_file="$LOG_DIR/.previous_uptime"
    local current_uptime=$(get_uptime_seconds)
    local previous_uptime=0

    # Read previous uptime if file exists
    if [ -f "$prev_uptime_file" ]; then
        previous_uptime=$(cat "$prev_uptime_file")
    fi

    # Save current uptime for next check
    echo "$current_uptime" > "$prev_uptime_file"

    # If current uptime is less than previous, a restart occurred
    if [ "$previous_uptime" -gt 0 ] && [ "$current_uptime" -lt "$previous_uptime" ]; then
        return 0  # Restart detected
    fi
    return 1  # No restart
}

################################################################################
# MAIN MONITORING FUNCTION
################################################################################

run_monitoring() {
    local uptime=$(get_uptime)
    local memory=$(get_memory_usage)
    local memory_pct=$(get_memory_percent)
    local load=$(get_load_average)
    local processes=$(get_process_count)
    local disk=$(get_disk_usage)
    local failed_units=$(get_failed_units)
    local ssh_status=$(get_ssh_status)
    local last_error=$(get_last_error)
    local container_state=$(get_container_state)

    # Check for restart
    local restart_detected="NO"
    if detect_restart; then
        restart_detected="YES"
        echo "[$TIMESTAMP] ⚠️  CONTAINER RESTART DETECTED" >> "$ALERT_FILE"
    fi

    # Log the data
    {
        echo "[$TIMESTAMP]"
        echo "  Uptime: $uptime"
        echo "  Memory: $memory ($memory_pct%)"
        echo "  Load Average: $load"
        echo "  Processes: $processes"
        echo "  Disk: $disk"
        echo "  SSH Port: $ssh_status"
        echo "  Container State: $container_state"
        echo "  Failed Units: $failed_units"
        echo "  Restart Detected: $restart_detected"

        if [ -n "$last_error" ] && [ "$last_error" != "No journal entries" ]; then
            echo "  Last Error: $last_error"
        fi
        echo ""
    } >> "$LOG_FILE"

    # Create JSON status file for easy parsing
    {
        echo "{"
        echo "  \"timestamp\": \"$TIMESTAMP\","
        echo "  \"uptime\": \"$uptime\","
        echo "  \"memory_used\": \"$memory\","
        echo "  \"memory_percent\": $memory_pct,"
        echo "  \"load_average\": \"$load\","
        echo "  \"processes\": $processes,"
        echo "  \"disk_usage\": \"$disk\","
        echo "  \"ssh_status\": \"$ssh_status\","
        echo "  \"container_state\": \"$container_state\","
        echo "  \"failed_units\": $failed_units,"
        echo "  \"restart_detected\": $restart_detected"
        echo "}"
    } > "$STATUS_FILE"

    # Alert on high memory usage
    if (( ${memory_pct%.*} > 85 )); then
        echo "[$TIMESTAMP] ⚠️  HIGH MEMORY USAGE: ${memory_pct}%" >> "$ALERT_FILE"
    fi

    # Alert on failed units
    if [ "$failed_units" -gt 0 ]; then
        echo "[$TIMESTAMP] ⚠️  FAILED SYSTEMD UNITS: $failed_units" >> "$ALERT_FILE"
    fi
}

################################################################################
# EXECUTE MONITORING
################################################################################

run_monitoring

# Return exit code 0 for successful execution
exit 0
