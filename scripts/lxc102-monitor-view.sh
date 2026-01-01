#!/bin/bash

################################################################################
# LXC 102 Container Stability Monitor - Viewer/Dashboard
#
# Purpose: Display monitoring data and health status
# Location: ~/scripts/lxc102-monitor-view.sh
# Usage: lxc102-monitor-view.sh [status|logs|alerts|summary|all]
################################################################################

LOG_DIR="$HOME/logs/lxc102-monitor"
DATE_ONLY=$(date '+%Y-%m-%d')
STATUS_FILE="$LOG_DIR/status-current.json"
LOG_FILE="$LOG_DIR/monitor-$DATE_ONLY.log"
ALERT_FILE="$LOG_DIR/alerts-$DATE_ONLY.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# DISPLAY FUNCTIONS
################################################################################

show_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  LXC 102 Container Stability Monitor - Dashboard${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

show_current_status() {
    echo -e "${BLUE}📊 CURRENT STATUS${NC}"
    echo "─────────────────────────────────────────────────────────"

    if [ ! -f "$STATUS_FILE" ]; then
        echo -e "${RED}❌ No status data available yet${NC}"
        echo "   (Monitoring script has not run yet)"
        return 1
    fi

    # Parse JSON and display
    local timestamp=$(grep '"timestamp"' "$STATUS_FILE" | cut -d'"' -f4)
    local uptime=$(grep '"uptime"' "$STATUS_FILE" | cut -d'"' -f4)
    local memory=$(grep '"memory_used"' "$STATUS_FILE" | cut -d'"' -f4)
    local memory_pct=$(grep '"memory_percent"' "$STATUS_FILE" | grep -o '[0-9.]*' | head -1)
    local load=$(grep '"load_average"' "$STATUS_FILE" | cut -d'"' -f4)
    local processes=$(grep '"processes"' "$STATUS_FILE" | grep -o '[0-9]*' | head -1)
    local disk=$(grep '"disk_usage"' "$STATUS_FILE" | cut -d'"' -f4)
    local ssh=$(grep '"ssh_status"' "$STATUS_FILE" | cut -d'"' -f4)
    local state=$(grep '"container_state"' "$STATUS_FILE" | cut -d'"' -f4)
    local failed=$(grep '"failed_units"' "$STATUS_FILE" | grep -o '[0-9]*' | tail -1)
    local restart=$(grep '"restart_detected"' "$STATUS_FILE" | cut -d'"' -f4)

    echo "Last Update:      $timestamp"
    echo "Uptime:           $uptime"
    echo "Container State:  $([ "$state" = "running" ] && echo -e "${GREEN}$state${NC}" || echo -e "${RED}$state${NC}")"
    echo ""
    echo "Memory Usage:     $memory ($(printf '%5.1f' $memory_pct)%)"
    echo "Load Average:     $load"
    echo "Processes:        $processes"
    echo "Disk Usage:       $disk"
    echo "SSH Port:         $([ "$ssh" = "OPEN" ] && echo -e "${GREEN}$ssh${NC}" || echo -e "${YELLOW}$ssh${NC}")"
    echo "Failed Units:     $([ "$failed" = "0" ] && echo -e "${GREEN}$failed${NC}" || echo -e "${RED}$failed${NC}")"
    echo ""

    # Restart detection
    if [ "$restart" = "YES" ]; then
        echo -e "Restart Detected: ${YELLOW}⚠️  YES - Container was restarted${NC}"
    else
        echo -e "Restart Detected: ${GREEN}✅ NO - Container is stable${NC}"
    fi

    echo ""
    return 0
}

show_logs() {
    echo -e "${BLUE}📋 RECENT LOGS (Last 30 entries)${NC}"
    echo "─────────────────────────────────────────────────────────"

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}❌ No logs available yet${NC}"
        return 1
    fi

    tail -30 "$LOG_FILE"
    echo ""
}

show_alerts() {
    echo -e "${BLUE}⚠️  ALERTS AND WARNINGS${NC}"
    echo "─────────────────────────────────────────────────────────"

    if [ ! -f "$ALERT_FILE" ]; then
        echo -e "${GREEN}✅ No alerts recorded${NC}"
        return 0
    fi

    local alert_count=$(wc -l < "$ALERT_FILE")
    if [ "$alert_count" -eq 0 ]; then
        echo -e "${GREEN}✅ No alerts recorded${NC}"
    else
        echo -e "Found ${RED}$alert_count${NC} alert(s):"
        echo ""
        cat "$ALERT_FILE"
    fi
    echo ""
}

show_summary() {
    echo -e "${BLUE}📈 STABILITY SUMMARY${NC}"
    echo "─────────────────────────────────────────────────────────"

    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}❌ No logs available yet${NC}"
        return 1
    fi

    local total_checks=$(grep -c "^\[" "$LOG_FILE")
    local restart_checks=$(grep -c "Restart Detected: YES" "$LOG_FILE")
    local alert_count=0
    [ -f "$ALERT_FILE" ] && alert_count=$(wc -l < "$ALERT_FILE")

    echo "Total Checks:          $total_checks"
    echo "Restarts Detected:     $([ "$restart_checks" -eq 0 ] && echo -e "${GREEN}$restart_checks${NC}" || echo -e "${YELLOW}$restart_checks${NC}")"
    echo "Alerts Recorded:       $([ "$alert_count" -eq 0 ] && echo -e "${GREEN}$alert_count${NC}" || echo -e "${RED}$alert_count${NC}")"
    echo ""

    # Uptime calculation
    if [ "$total_checks" -gt 0 ]; then
        echo "Monitoring Duration:   ~$((total_checks * 5)) minutes"
        echo "Monitoring Started:    $(head -1 "$LOG_FILE" | grep -o '\[.*\]' | tr -d '[]')"
    fi
    echo ""

    # Health assessment
    if [ "$restart_checks" -eq 0 ] && [ "$alert_count" -eq 0 ]; then
        echo -e "Overall Assessment:    ${GREEN}✅ EXCELLENT - No issues detected${NC}"
    elif [ "$restart_checks" -eq 0 ] && [ "$alert_count" -lt 3 ]; then
        echo -e "Overall Assessment:    ${YELLOW}⚠️  GOOD - Minor warnings recorded${NC}"
    else
        echo -e "Overall Assessment:    ${RED}⚠️  NEEDS ATTENTION - Multiple issues detected${NC}"
    fi
    echo ""
}

show_help() {
    echo "Usage: lxc102-monitor-view.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  status      Show current container status"
    echo "  logs        Show recent monitoring logs"
    echo "  alerts      Show alerts and warnings"
    echo "  summary     Show stability summary"
    echo "  all         Show all of the above (default)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  lxc102-monitor-view.sh status"
    echo "  lxc102-monitor-view.sh alerts"
    echo "  lxc102-monitor-view.sh all"
}

################################################################################
# MAIN
################################################################################

main() {
    local option="${1:-all}"

    case "$option" in
        status)
            show_header
            show_current_status
            ;;
        logs)
            show_header
            show_logs
            ;;
        alerts)
            show_header
            show_alerts
            ;;
        summary)
            show_header
            show_summary
            ;;
        all)
            show_header
            show_current_status
            show_logs
            show_alerts
            show_summary
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $option"
            show_help
            exit 1
            ;;
    esac

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

main "$@"
