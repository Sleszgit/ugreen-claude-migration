#!/bin/bash
#
# Installer for Auto-Update Sudoers Configuration
# Run this script once to enable passwordless updates
#

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Auto-Update Sudoers Configuration Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will configure passwordless sudo for:"
echo "  • npm update -g @anthropic-ai/claude-code"
echo "  • apt update"
echo "  • apt upgrade -y"
echo "  • apt autoremove -y"
echo ""
echo "This is SAFE because it only allows these specific commands."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

# Validate sudoers file syntax
echo "Validating sudoers configuration..."
if ! sudo visudo -c -f /tmp/auto-update-sudoers; then
    echo "❌ ERROR: Sudoers file has invalid syntax!"
    exit 1
fi

# Install sudoers file
echo "Installing sudoers configuration..."
sudo cp /tmp/auto-update-sudoers /etc/sudoers.d/auto-update
sudo chmod 0440 /etc/sudoers.d/auto-update
sudo chown root:root /etc/sudoers.d/auto-update

# Verify installation
if sudo -n apt update --dry-run > /dev/null 2>&1; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ SUCCESS! Auto-update is now configured."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The auto-update script will run once per day on login."
    echo "You can also run it manually: ~/scripts/auto-update/.auto-update.sh"
    echo "Log file: ~/logs/.auto-update.log"
    echo ""
else
    echo ""
    echo "❌ Installation may have failed. Please check /etc/sudoers.d/auto-update"
    exit 1
fi
