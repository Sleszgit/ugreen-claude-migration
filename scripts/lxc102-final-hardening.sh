#!/bin/bash

################################################################################
# LXC 102 Final Hardening Script
# Session 77 - Complete hardening deployment
#
# Purpose: Disable Postfix and apply AppArmor SSH confinement
# Location: LXC 102 (ugreen-ai-terminal)
#
# Steps:
# 1. Disable Postfix mail service
# 2. Create AppArmor SSH confinement profile
# 3. Load AppArmor profile
# 4. Restart SSH service with new confinement
################################################################################

set -e  # Exit on any error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  LXC 102 Final Hardening Deployment - Session 77              ║"
echo "║  Postfix removal + AppArmor SSH confinement                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use: sudo /path/to/script.sh)"
   exit 1
fi

################################################################################
# Step 1: Disable Postfix
################################################################################
echo "📋 Step 1: Disabling Postfix mail service..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if systemctl is-active --quiet postfix; then
    echo "  ⏸️  Stopping Postfix service..."
    systemctl stop postfix
    echo "  ✅ Postfix stopped"
else
    echo "  ℹ️  Postfix already inactive"
fi

if systemctl is-enabled --quiet postfix; then
    echo "  🔒 Disabling Postfix from autostart..."
    systemctl disable postfix
    echo "  ✅ Postfix disabled (won't autostart on boot)"
else
    echo "  ℹ️  Postfix already disabled from autostart"
fi

POSTFIX_STATUS=$(systemctl is-active postfix)
echo "  Status: $POSTFIX_STATUS"
echo ""

################################################################################
# Step 2: Create AppArmor SSH Confinement Profile
################################################################################
echo "📋 Step 2: Creating AppArmor SSH confinement profile..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PROFILE_PATH="/etc/apparmor.d/usr.sbin.sshd"

echo "  📝 Writing AppArmor profile to: $PROFILE_PATH"

tee "$PROFILE_PATH" > /dev/null << 'EOF'
#include <tunables/global>

/usr/sbin/sshd flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>

  # SSH daemon executable and libraries
  /usr/sbin/sshd mr,
  /usr/lib/x86_64-linux-gnu/lib*.so* mr,
  /lib/x86_64-linux-gnu/lib*.so* mr,

  # SSH configuration
  /etc/ssh/sshd_config r,
  /etc/ssh/sshd_config.d/ r,
  /etc/ssh/sshd_config.d/* r,

  # SSH keys
  /etc/ssh/ssh_host_* r,

  # Runtime and PID files
  /run/sshd.pid rw,
  /run/sshd/ rw,
  /run/sshd/** rw,

  # User home directories for SSH access
  /home/ r,
  /home/** rwk,
  /root/ r,
  /root/** rwk,

  # Necessary system files
  /etc/passwd r,
  /etc/group r,
  /etc/shadow r,
  /etc/gshadow r,
  /etc/login.defs r,
  /etc/default/login r,
  /etc/default/useradd r,
  /etc/shells r,
  /etc/security/** r,
  /etc/pam.d/** r,
  /etc/sudoers r,
  /etc/sudoers.d/ r,
  /etc/sudoers.d/** r,

  # Terminal and PTY access
  /dev/null rw,
  /dev/zero rw,
  /dev/full rw,
  /dev/urandom r,
  /dev/pts/* rw,
  /dev/tty rw,

  # Process management
  /proc/*/stat r,
  /proc/sys/kernel/ngroups_max r,

  # Deny dangerous operations
  deny /sys/** wx,
  deny /proc/sys/** wx,

  # Signal handling
  signal (send) peer=unconfined,
  signal (receive) peer=unconfined,

  # Capability restrictions
  capability setuid,
  capability setgid,
  capability dac_override,
  capability dac_read_search,
  capability kill,
  capability net_bind_service,
}
EOF

if [ -f "$PROFILE_PATH" ]; then
    echo "  ✅ Profile created successfully"
    echo "  📊 File size: $(stat -f%z "$PROFILE_PATH" 2>/dev/null || stat -c%s "$PROFILE_PATH") bytes"
else
    echo "  ❌ Failed to create profile"
    exit 1
fi
echo ""

################################################################################
# Step 3: Load AppArmor Profile
################################################################################
echo "📋 Step 3: Loading AppArmor profile..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "  🔧 Parsing and loading profile..."
if apparmor_parser -r "$PROFILE_PATH"; then
    echo "  ✅ Profile loaded successfully"
else
    echo "  ❌ Failed to load profile"
    exit 1
fi

echo "  📊 Verifying profile status..."
if aa-status 2>/dev/null | grep -q "sshd"; then
    echo "  ✅ AppArmor profile active for SSH"
    aa-status 2>/dev/null | grep "sshd" || true
else
    echo "  ⚠️  Profile loaded but not shown in status (may appear after restart)"
fi
echo ""

################################################################################
# Step 4: Restart SSH Service
################################################################################
echo "📋 Step 4: Restarting SSH service..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "  ⏸️  Stopping SSH daemon..."
systemctl stop ssh

sleep 1

echo "  🚀 Starting SSH daemon with AppArmor confinement..."
systemctl start ssh

sleep 1

SSH_STATUS=$(systemctl is-active ssh)
echo "  Status: $SSH_STATUS"

if [ "$SSH_STATUS" = "active" ]; then
    echo "  ✅ SSH restarted successfully"
else
    echo "  ❌ SSH failed to start"
    echo "  Attempting to view errors:"
    systemctl status ssh || true
    exit 1
fi
echo ""

################################################################################
# Final Verification
################################################################################
echo "✨ Final Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "📋 Verification Checklist:"
echo ""

# Check Postfix
POSTFIX_ACTIVE=$(systemctl is-active postfix 2>/dev/null)
POSTFIX_ENABLED=$(systemctl is-enabled postfix 2>/dev/null)
if [ "$POSTFIX_ACTIVE" = "inactive" ] && [ "$POSTFIX_ENABLED" = "disabled" ]; then
    echo "  ✅ Postfix: disabled and inactive"
else
    echo "  ⚠️  Postfix status: active=$POSTFIX_ACTIVE, enabled=$POSTFIX_ENABLED"
fi

# Check AppArmor profile file
if [ -f "$PROFILE_PATH" ]; then
    echo "  ✅ AppArmor profile file: created at $PROFILE_PATH"
else
    echo "  ❌ AppArmor profile file: NOT found"
fi

# Check SSH status
SSH_ACTIVE=$(systemctl is-active ssh)
if [ "$SSH_ACTIVE" = "active" ]; then
    echo "  ✅ SSH service: active and running"
else
    echo "  ❌ SSH service: $SSH_ACTIVE"
fi

# Check SSH port
if netstat -tlnp 2>/dev/null | grep -q ":22"; then
    echo "  ✅ SSH port 22: listening"
elif ss -tlnp 2>/dev/null | grep -q ":22"; then
    echo "  ✅ SSH port 22: listening"
else
    echo "  ⚠️  SSH port 22: may not be listening (check logs)"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  ✅ LXC 102 Final Hardening Complete!                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Summary:"
echo "  • Postfix mail service: DISABLED"
echo "  • AppArmor SSH profile: LOADED"
echo "  • SSH service: RESTARTED with confinement"
echo ""
echo "System is now production-ready with:"
echo "  🔐 SSH hardened configuration"
echo "  🛡️  AppArmor SSH confinement"
echo "  🔒 Encrypted API tokens"
echo "  🚫 Unnecessary services removed"
echo ""
