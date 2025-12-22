#!/bin/bash
# Start aaafilmscopy transfer in screen session
# Run as root: sudo bash start-aaafilmscopy.sh

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo"
    exit 1
fi

echo "========================================="
echo "Starting aaafilmscopy Copy in Screen"
echo "========================================="
echo ""

# Check if screen is installed
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    apt update -qq && apt install -y screen
fi

# Check if screen session already exists
if screen -ls | grep -q "aaafilmscopy"; then
    echo "Screen session 'aaafilmscopy' already exists!"
    echo ""
    echo "To view it: screen -r aaafilmscopy"
    echo "To kill it: screen -X -S aaafilmscopy quit"
    exit 1
fi

# Start the copy in screen
echo "Starting copy in background screen session..."
screen -dmS aaafilmscopy bash /home/sleszugreen/copy-aaafilmscopy.sh

sleep 2

# Check if started
if screen -ls | grep -q "aaafilmscopy"; then
    echo "✅ Copy started successfully!"
    echo ""
    echo "Screen session: 'aaafilmscopy'"
    echo ""
    echo "To monitor progress:"
    echo "  screen -r aaafilmscopy"
    echo ""
    echo "To detach (keep running):"
    echo "  Press: Ctrl+A then D"
    echo ""
    echo "To check if still running:"
    echo "  screen -ls"
    echo ""
else
    echo "❌ Failed to start screen session"
    exit 1
fi
