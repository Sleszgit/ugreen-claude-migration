#!/bin/bash
# Quick start script to launch both transfers in screen sessions
# Run on Proxmox host (192.168.40.60) as root

echo "=== 918 to UGREEN Transfer - Quick Start ==="
echo ""

# Check if we're on the Proxmox host
if [ ! -d "/mnt/918-filmy918" ] || [ ! -d "/mnt/918-series918" ]; then
    echo "ERROR: NFS mounts not found!"
    echo "This script must run on the Proxmox host (192.168.40.60)"
    echo "Make sure you ran setup-nfs-mounts.sh first"
    exit 1
fi

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    apt update && apt install -y screen
fi

# Copy scripts to /root if not already there
SCRIPT_DIR="/root/nas-transfer"
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Copying scripts to $SCRIPT_DIR..."
    mkdir -p "$SCRIPT_DIR"
    cp /home/sleszugreen/nas-transfer/*.sh "$SCRIPT_DIR/"
    chmod +x "$SCRIPT_DIR"/*.sh
fi

# Create logs directory
mkdir -p /root/nas-transfer-logs

echo ""
echo "Starting transfer sessions..."
echo ""

# Start movies transfer
echo "1. Starting MOVIES transfer in screen session 'movies'..."
screen -dmS movies bash "$SCRIPT_DIR/transfer-movies-nfs.sh"
sleep 1

if screen -list | grep -q "movies"; then
    echo "   ✓ Movies transfer started"
else
    echo "   ✗ Failed to start movies transfer"
fi

# Start TV shows transfer
echo "2. Starting TV SHOWS transfer in screen session 'tvshows'..."
screen -dmS tvshows bash "$SCRIPT_DIR/transfer-tvshows-nfs.sh"
sleep 1

if screen -list | grep -q "tvshows"; then
    echo "   ✓ TV shows transfer started"
else
    echo "   ✗ Failed to start TV shows transfer"
fi

echo ""
echo "=== Transfers Started! ==="
echo ""
echo "Active screen sessions:"
screen -ls
echo ""
echo "📋 How to monitor:"
echo ""
echo "  View movies transfer:"
echo "    screen -r movies"
echo ""
echo "  View TV shows transfer:"
echo "    screen -r tvshows"
echo ""
echo "  Detach from screen: Press Ctrl+A then D"
echo ""
echo "  Check logs:"
echo "    tail -f /root/nas-transfer-logs/movies-nfs-*.log"
echo "    tail -f /root/nas-transfer-logs/tvshows-nfs-*.log"
echo ""
echo "  Watch disk usage:"
echo "    watch -n 5 'du -sh /storage/Media/Movies918/* /storage/Media/Series918/*'"
echo ""
