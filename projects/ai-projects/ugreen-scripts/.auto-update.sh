#!/bin/bash
#
# Auto-Update Script for UGREEN LXC 102
# Updates Claude Code and system packages
# Logs to ~/logs/.auto-update.log
#

LOG_FILE="$HOME/logs/.auto-update.log"
LOCK_FILE="$HOME/.auto-update.lock"
LAST_RUN_FILE="$HOME/.auto-update.lastrun"

# Color codes for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to log without displaying
log_silent() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if we should run (only once per day)
should_run() {
    if [ ! -f "$LAST_RUN_FILE" ]; then
        return 0  # First run
    fi

    last_run=$(cat "$LAST_RUN_FILE")
    current_date=$(date '+%Y-%m-%d')

    if [ "$last_run" != "$current_date" ]; then
        return 0  # New day, should run
    else
        return 1  # Already ran today
    fi
}

# Check for lock file (prevent multiple simultaneous runs)
if [ -f "$LOCK_FILE" ]; then
    log_silent "Update already running (lock file exists), skipping..."
    exit 0
fi

# Check if we should run today
if ! should_run; then
    log_silent "Updates already ran today, skipping..."
    exit 0
fi

# Create lock file
touch "$LOCK_FILE"

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# Start update process
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔄 Auto-Update Starting...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log "=== Auto-Update Started ==="

# Update Claude Code
echo -e "\n${YELLOW}📦 Updating Claude Code...${NC}"
log "Checking Claude Code version..."

CURRENT_VERSION=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
log "Current Claude Code version: $CURRENT_VERSION"

echo -e "${BLUE}   Current version: $CURRENT_VERSION${NC}"
log "Running: sudo npm update -g @anthropic-ai/claude-code"

if sudo npm update -g @anthropic-ai/claude-code >> "$LOG_FILE" 2>&1; then
    NEW_VERSION=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
        echo -e "${GREEN}   ✓ Claude Code updated: $CURRENT_VERSION → $NEW_VERSION${NC}"
        log "SUCCESS: Claude Code updated from $CURRENT_VERSION to $NEW_VERSION"
    else
        echo -e "${GREEN}   ✓ Claude Code is up to date ($CURRENT_VERSION)${NC}"
        log "Claude Code already at latest version: $CURRENT_VERSION"
    fi
else
    echo -e "${RED}   ✗ Failed to update Claude Code${NC}"
    log "ERROR: Failed to update Claude Code"
fi

# Update system packages
echo -e "\n${YELLOW}📦 Updating system packages...${NC}"
log "Running: sudo apt update"

if sudo apt update >> "$LOG_FILE" 2>&1; then
    echo -e "${GREEN}   ✓ Package list updated${NC}"
    log "SUCCESS: apt update completed"

    # Check if there are upgradable packages
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

    if [ "$UPGRADABLE" -gt 1 ]; then
        echo -e "${YELLOW}   Found $((UPGRADABLE - 1)) upgradable package(s)${NC}"
        log "Found $((UPGRADABLE - 1)) upgradable packages"
        log "Running: sudo apt upgrade -y"

        if sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}   ✓ System packages upgraded${NC}"
            log "SUCCESS: apt upgrade completed"
        else
            echo -e "${RED}   ✗ Failed to upgrade packages${NC}"
            log "ERROR: apt upgrade failed"
        fi
    else
        echo -e "${GREEN}   ✓ All packages are up to date${NC}"
        log "All system packages already up to date"
    fi

    # Auto-remove unused packages
    log "Running: sudo apt autoremove -y"
    if sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}   ✓ Removed unused packages${NC}"
        log "SUCCESS: apt autoremove completed"
    fi
else
    echo -e "${RED}   ✗ Failed to update package list${NC}"
    log "ERROR: apt update failed"
fi

# Update last run timestamp
date '+%Y-%m-%d' > "$LAST_RUN_FILE"

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Auto-Update Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Full log: $LOG_FILE${NC}\n"
log "=== Auto-Update Completed Successfully ==="
