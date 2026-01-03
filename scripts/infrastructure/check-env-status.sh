#!/usr/bin/env bash
# =============================================================================
# Environment Status Check Script
# =============================================================================
# Purpose: Generate real-time connectivity status for Claude Code
# Output: SESSION_STATUS.md in ~/.claude/
# Usage: Run at session start to see what's working
# =============================================================================

set -Euo pipefail
# Note: -e removed to allow failed checks without exiting

OUTPUT_FILE="$HOME/.claude/SESSION_STATUS.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for terminal output (stripped in file)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "Checking environment status..."

# Start the output file
cat > "$OUTPUT_FILE" << EOF
# Session Status Report
**Generated:** $TIMESTAMP
**Location:** LXC 102 (ugreen-ai-terminal) @ 192.168.40.82

## Connection Status

| Host | IP | Method | Status | Notes |
|------|-----|--------|--------|-------|
EOF

# Function to check SSH
check_ssh() {
    local name="$1"
    local host="$2"
    local port="${3:-22}"
    local timeout="${4:-3}"

    if timeout "$timeout" bash -c "cat </dev/null >/dev/tcp/$host/$port" 2>/dev/null; then
        echo "| $name | $host | SSH:$port | UP | Port open |" >> "$OUTPUT_FILE"
        echo -e "${GREEN}[OK]${NC} $name ($host:$port)"
        return 0
    else
        echo "| $name | $host | SSH:$port | DOWN | Connection failed |" >> "$OUTPUT_FILE"
        echo -e "${RED}[FAIL]${NC} $name ($host:$port)"
        return 1
    fi
}

# Function to check API endpoint
check_api() {
    local name="$1"
    local url="$2"
    local token_file="$3"
    local token_id="$4"

    if [ ! -f "$token_file" ]; then
        echo "| $name | - | API | NO TOKEN | Token file missing |" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}[WARN]${NC} $name - token file missing"
        return 1
    fi

    local token=$(cat "$token_file")
    local response=$(timeout 5 curl -s -k -o /dev/null -w "%{http_code}" \
        --connect-timeout 3 \
        -H "Authorization: PVEAPIToken=$token_id=$token" \
        "$url" 2>/dev/null || echo "000")

    if [ "$response" = "200" ]; then
        echo "| $name | - | API | UP | HTTP 200 |" >> "$OUTPUT_FILE"
        echo -e "${GREEN}[OK]${NC} $name API"
        return 0
    else
        echo "| $name | - | API | DOWN | HTTP $response |" >> "$OUTPUT_FILE"
        echo -e "${RED}[FAIL]${NC} $name API (HTTP $response)"
        return 1
    fi
}

# Function to check ping
check_ping() {
    local name="$1"
    local host="$2"

    if ping -c 1 -W 2 "$host" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

echo ""
echo "=== Checking SSH Connections ==="

# Check Homelab SSH
check_ssh "Homelab" "192.168.40.40" 22

# Check 920 NAS SSH
check_ssh "920 NAS" "192.168.40.20" 22

# Check UGREEN Host SSH (known broken)
check_ssh "UGREEN Host" "192.168.40.60" 22022 || true

# Check Pi400
check_ssh "Pi400" "192.168.40.50" 22 || true

# Check Pi3B
check_ssh "Pi3B" "192.168.40.30" 22 || true

echo ""
echo "=== Checking API Endpoints ==="

# Check UGREEN Proxmox API - first check if port is even reachable
if timeout 2 bash -c "cat </dev/null >/dev/tcp/192.168.40.60/8006" 2>/dev/null; then
    check_api "UGREEN API" \
        "https://192.168.40.60:8006/api2/json/version" \
        "$HOME/.proxmox-api-token" \
        "claude-reader@pam!claude-token"
else
    echo "| UGREEN API | 192.168.40.60 | API:8006 | BLOCKED | Port unreachable (firewall) |" >> "$OUTPUT_FILE"
    echo -e "${RED}[BLOCKED]${NC} UGREEN API (port 8006 firewall blocked)"
fi

# Add summary section
cat >> "$OUTPUT_FILE" << 'EOF'

## Quick Reference

**Working Connections:**
EOF

# Count working connections
echo "" >> "$OUTPUT_FILE"

# Add quick commands
cat >> "$OUTPUT_FILE" << 'EOF'
**Commands to use:**
- Homelab: `ssh homelab`
- 920 NAS: `ssh backup-user@192.168.40.20`
- UGREEN API: Use curl with token (see ENVIRONMENT.yaml)

## Warnings

- **192.168.40.60** = UGREEN (where I run) - NOT homelab
- **192.168.40.40** = HOMELAB (main Proxmox server)
- Use `ssh ugreen-host` for UGREEN, `ssh homelab` for Homelab

---
*Run `~/scripts/infrastructure/check-env-status.sh` to regenerate*
EOF

echo ""
echo "=== Status report saved to: $OUTPUT_FILE ==="
echo ""
cat "$OUTPUT_FILE"
