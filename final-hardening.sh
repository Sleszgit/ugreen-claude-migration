#!/bin/bash
# LXC 102 Final Hardening Script - Session 77
# EXECUTE THIS IN: LXC 102 CONTAINER (ugreen-ai-terminal)
# Command: bash ~/final-hardening.sh

echo "Starting hardening..."

# Step 1: Disable Postfix
echo "Step 1: Disabling Postfix..."
sudo systemctl disable postfix
sudo systemctl stop postfix
echo "✓ Postfix disabled"

# Step 2: Create AppArmor profile
echo "Step 2: Creating AppArmor profile..."
sudo cat > /etc/apparmor.d/usr.sbin.sshd << 'PROFILE'
#include <tunables/global>

/usr/sbin/sshd flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>

  /usr/sbin/sshd mr,
  /usr/lib/x86_64-linux-gnu/lib*.so* mr,
  /lib/x86_64-linux-gnu/lib*.so* mr,

  /etc/ssh/sshd_config r,
  /etc/ssh/sshd_config.d/ r,
  /etc/ssh/sshd_config.d/* r,

  /etc/ssh/ssh_host_* r,

  /run/sshd.pid rw,
  /run/sshd/ rw,
  /run/sshd/** rw,

  /home/ r,
  /home/** rwk,
  /root/ r,
  /root/** rwk,

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

  /dev/null rw,
  /dev/zero rw,
  /dev/full rw,
  /dev/urandom r,
  /dev/pts/* rw,
  /dev/tty rw,

  /proc/*/stat r,
  /proc/sys/kernel/ngroups_max r,

  deny /sys/** wx,
  deny /proc/sys/** wx,

  signal (send) peer=unconfined,
  signal (receive) peer=unconfined,

  capability setuid,
  capability setgid,
  capability dac_override,
  capability dac_read_search,
  capability kill,
  capability net_bind_service,
}
PROFILE
echo "✓ AppArmor profile created"

# Step 3: Load AppArmor profile
echo "Step 3: Loading AppArmor profile..."
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.sshd
echo "✓ AppArmor profile loaded"

# Step 4: Restart SSH
echo "Step 4: Restarting SSH..."
sudo systemctl restart ssh
sleep 2
echo "✓ SSH restarted"

# Verify
echo ""
echo "Verification:"
echo "  Postfix: $(systemctl is-active postfix)"
echo "  SSH: $(systemctl is-active ssh)"
echo "  Profile: $([ -f /etc/apparmor.d/usr.sbin.sshd ] && echo 'exists' || echo 'missing')"
echo ""
echo "✓ Hardening complete!"
