# Proxmox Security Hardening Plan
## UGREEN DXP4800+ (192.168.40.60)

---

## Current Security Assessment

**Status:** ⚠️ **WEAK** - Fresh installation with default settings

### Critical Issues Found:
- 🚨 Root SSH login enabled
- 🚨 No firewall rules configured (pve-firewall running but empty config)
- 🚨 No fail2ban protection against brute-force attacks
- 🚨 SSH key authentication not enforced
- ⚠️ No automatic security updates configured
- ⚠️ Default SSH port 22 in use

### Environment Details:
- **OS:** Debian GNU/Linux 13 (Trixie)
- **Proxmox Version:** 9.1.2
- **Current User:** sleszugreen (has sudo)
- **Network:** 192.168.40.60
- **SSH Config:** /etc/ssh/sshd_config
- **Firewall Config:** /etc/pve/firewall/

---

## User Requirements

- **Trusted IP:** 192.168.99.6 (desktop - DHCP reservation in UniFi)
- **Netbird Access:** To be added later after Netbird installation
- **SSH Port:** Change to **22022** (non-standard but memorable)
- **SSH Keys:** Need to set up key-based authentication (user needs guidance)
- **Notifications:** Use ntfy.sh (no email passwords needed)
- **Physical Access:** Available NOW but box will be moved to remote location
- **Critical Priority:** Ensure bulletproof remote access before moving box

---

## CRITICAL: Remote Access Priority

⚠️ **The UGREEN box will be moved to a location without monitor/keyboard access.**

**Implementation Strategy:**
- **Phase A (BEFORE MOVING BOX):** Establish and thoroughly test remote access
- **Phase B (BEFORE MOVING BOX):** Harden security with extensive testing
- **Phase C (AFTER MOVING BOX):** Add monitoring and protection layers
- **Phase D (OPTIONAL):** Additional enhancements

**Mandatory Pre-Move Checklist:**
- Multiple SSH access tests from desktop
- Proxmox Web UI access confirmed
- Emergency console access via web UI tested
- Backup access methods verified
- Recovery procedures documented and tested

---

## Implementation Plan

### PHASE A: REMOTE ACCESS FOUNDATION (BEFORE MOVING BOX)

---

### Phase 0: Repository Configuration (CRITICAL - DO FIRST)
**Purpose:** Fix Proxmox repositories to enable updates and remove annoying popups

#### Script 0: `00-repository-setup.sh`
**Location:** `/root/proxmox-hardening/00-repository-setup.sh`

**Actions:**
1. Check current repository configuration:
   ```bash
   cat /etc/apt/sources.list
   cat /etc/apt/sources.list.d/pve-enterprise.list
   cat /etc/apt/sources.list.d/ceph.list
   ```

2. Disable Enterprise repository (requires paid subscription):
   ```bash
   # Comment out or disable
   echo "# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
   ```

3. Add no-subscription repository (free updates):
   ```bash
   # Add to /etc/apt/sources.list.d/pve-no-subscription.list
   echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
   ```

4. Update package lists:
   ```bash
   apt update
   ```

5. Verify repositories working:
   ```bash
   apt-cache policy pve-manager
   ```

**Critical Files:**
- /etc/apt/sources.list
- /etc/apt/sources.list.d/pve-enterprise.list
- /etc/apt/sources.list.d/pve-no-subscription.list

**Benefits:**
- ✅ Removes "No valid subscription" popup on Web UI login
- ✅ Enables free security updates
- ✅ Access to community-supported packages

---

### Phase 0.5: Time Synchronization (CRITICAL)
**Purpose:** Ensure accurate time for security certificates and logging

#### Script 0.5: `00.5-ntp-setup.sh`
**Location:** `/root/proxmox-hardening/00.5-ntp-setup.sh`

**Actions:**
1. Check current time and timezone:
   ```bash
   timedatectl status
   ```

2. Set timezone to Europe/Warsaw:
   ```bash
   timedatectl set-timezone Europe/Warsaw
   ```

3. Verify NTP service (systemd-timesyncd):
   ```bash
   systemctl status systemd-timesyncd
   ```

4. Configure NTP servers in `/etc/systemd/timesyncd.conf`:
   ```ini
   [Time]
   NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
   FallbackNTP=0.europe.pool.ntp.org 1.europe.pool.ntp.org
   ```

5. Restart time sync service:
   ```bash
   systemctl restart systemd-timesyncd
   ```

6. Enable NTP synchronization:
   ```bash
   timedatectl set-ntp true
   ```

7. Verify synchronization:
   ```bash
   timedatectl timesync-status
   ```

**Critical Files:**
- /etc/systemd/timesyncd.conf

**Benefits:**
- ✅ Accurate timestamps for logs and security events
- ✅ Prevents SSL/TLS certificate errors
- ✅ Essential for fail2ban and authentication

---

### Phase 1: Pre-Hardening Setup & Emergency Access
**Purpose:** Ensure we don't lock ourselves out during hardening

#### Script 1: `01-pre-hardening-checks.sh`
**Location:** `/root/proxmox-hardening/01-pre-hardening-checks.sh`

**Actions:**
1. Create hardening directory structure
2. Verify console access available
3. **CRITICAL:** Verify Proxmox Web UI is accessible from 192.168.99.6:
   ```bash
   # Test from desktop:
   curl -k https://192.168.40.60:8006
   ```
4. Backup all configuration files:
   - /etc/ssh/sshd_config → /root/proxmox-hardening/backups/sshd_config.backup
   - /etc/pve/firewall/ → /root/proxmox-hardening/backups/firewall/
   - /etc/fail2ban/ (after installation) → backups
   - /etc/apt/sources.list* → backups
   - /etc/systemd/timesyncd.conf → backups
5. Document rollback procedures
6. Create emergency access script
7. Test sudo access
8. Record current IP address (192.168.99.6)
9. **Verify Proxmox Shell access via Web UI works**
10. Display pre-flight checklist

**Safety Checks:**
- Verify user is sleszugreen with sudo
- Confirm running on Proxmox host (check /etc/pve exists)
- Check network connectivity
- Warn about keeping second terminal open
- **Test Web UI emergency console access**

**Output:**
- Backup directory created
- Rollback instructions file
- Pre-flight checklist confirmation
- **Emergency access methods documented**

**CRITICAL: Emergency Access Verification**
Before proceeding, user must confirm:
- [ ] Can access Proxmox Web UI at https://192.168.40.60:8006
- [ ] Can login to Web UI with sleszugreen account
- [ ] Can open Shell via Web UI (Datacenter > Node > Shell)
- [ ] Shell via Web UI allows sudo commands

---

### Phase 2: SMART Disk Monitoring Setup
**Purpose:** Monitor disk health and prevent data loss from disk failure

#### Script 2: `02-smart-monitoring.sh`
**Location:** `/root/proxmox-hardening/02-smart-monitoring.sh`

**Actions:**
1. Install smartmontools:
   ```bash
   apt install smartmontools -y
   ```

2. Detect all disks:
   ```bash
   lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT
   ```

3. Test SMART capability on all disks:
   ```bash
   for disk in /dev/sd? /dev/nvme?n?; do
       [ -e "$disk" ] && smartctl -i "$disk"
   done
   ```

4. Enable SMART on all capable disks:
   ```bash
   for disk in /dev/sd? /dev/nvme?n?; do
       [ -e "$disk" ] && smartctl -s on "$disk"
   done
   ```

5. Run initial health check:
   ```bash
   for disk in /dev/sd? /dev/nvme?n?; do
       [ -e "$disk" ] && echo "=== $disk ===" && smartctl -H "$disk"
   done
   ```

6. Configure automatic SMART monitoring in `/etc/smartd.conf`:
   ```bash
   # Monitor all disks, run short test daily, long test weekly
   DEVICESCAN -a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,35,40 -m root
   ```

7. Set up email/ntfy alerts for SMART failures:
   ```bash
   # Create /usr/local/bin/smart-alert.sh
   #!/bin/bash
   DISK="$1"
   MESSAGE="$2"
   /usr/local/bin/send-security-alert.sh "SMART Alert: Disk $DISK - $MESSAGE" "urgent"
   ```

8. Enable and start smartd service:
   ```bash
   systemctl enable smartd
   systemctl start smartd
   ```

9. Display SMART status summary:
   ```bash
   /usr/local/bin/smart-status.sh  # Show all disk health
   ```

**Critical Files:**
- /etc/smartd.conf
- /usr/local/bin/smart-alert.sh
- /usr/local/bin/smart-status.sh

**Benefits:**
- ✅ Early warning of disk failures
- ✅ Automatic disk health monitoring
- ✅ Scheduled self-tests
- ✅ Alerts via ntfy before data loss

**SMART Test Schedule:**
- Short test: Daily at 2 AM
- Long test: Weekly on Saturday at 3 AM

---

### Phase 3: SSH Key Setup (BEFORE SSH Hardening!)
**Purpose:** Set up key authentication before disabling passwords

#### Script 3: `03-ssh-key-setup.sh`
**Location:** `/root/proxmox-hardening/03-ssh-key-setup.sh`

**Actions:**
1. **Display SSH key generation instructions for user's desktop (192.168.99.6):**
   ```bash
   cat << 'EOF'
   =============================================================
   SSH KEY GENERATION INSTRUCTIONS - RUN ON YOUR DESKTOP
   =============================================================

   1. Open terminal on your desktop (192.168.99.6)

   2. Check if you already have SSH keys:
      ls -la ~/.ssh/id_*

      If you see id_rsa and id_rsa.pub, you already have keys!
      Skip to step 4.

   3. Generate new SSH key pair:
      ssh-keygen -t ed25519 -C "sleszugreen@ugreen-proxmox"

      When prompted:
      - Press Enter to accept default location (~/.ssh/id_ed25519)
      - Enter a passphrase (RECOMMENDED for security) or press Enter for no passphrase
      - Confirm passphrase

      Alternative (if ed25519 not supported):
      ssh-keygen -t rsa -b 4096 -C "sleszugreen@ugreen-proxmox"

   4. Display your public key:
      cat ~/.ssh/id_ed25519.pub
      # OR
      cat ~/.ssh/id_rsa.pub

   5. Copy the ENTIRE output (starts with "ssh-ed25519" or "ssh-rsa")

   =============================================================
   EOF
   ```

2. Create ~/.ssh directory for sleszugreen if not exists:
   ```bash
   mkdir -p /home/sleszugreen/.ssh
   chmod 700 /home/sleszugreen/.ssh
   chown sleszugreen:sleszugreen /home/sleszugreen/.ssh
   ```

3. **Interactive: Prompt user to paste their public key:**
   ```bash
   echo "Paste your SSH public key (from desktop) and press Enter:"
   read -r ssh_public_key
   echo "$ssh_public_key" >> /home/sleszugreen/.ssh/authorized_keys
   ```

4. Set correct permissions:
   ```bash
   chmod 600 /home/sleszugreen/.ssh/authorized_keys
   chown sleszugreen:sleszugreen /home/sleszugreen/.ssh/authorized_keys
   ```

5. **Create emergency root access (safety backup):**
   ```bash
   mkdir -p /root/.ssh
   chmod 700 /root/.ssh
   echo "$ssh_public_key" >> /root/.ssh/authorized_keys
   chmod 600 /root/.ssh/authorized_keys
   ```

6. Display test command:
   ```bash
   cat << 'EOF'
   =============================================================
   TEST SSH KEY AUTHENTICATION
   =============================================================

   From your desktop (192.168.99.6), open a NEW terminal and test:

   ssh sleszugreen@192.168.40.60

   If using ed25519 key:
   ssh -i ~/.ssh/id_ed25519 sleszugreen@192.168.40.60

   If using rsa key:
   ssh -i ~/.ssh/id_rsa sleszugreen@192.168.40.60

   You should login WITHOUT being asked for a password!
   (If you set a passphrase, you'll be asked for the KEY passphrase, not the server password)

   DO NOT CONTINUE until this works!!!
   =============================================================
   EOF
   ```

7. **WAIT FOR USER CONFIRMATION** before proceeding:
   ```bash
   read -p "Have you successfully tested SSH key login? (yes/no): " confirmation
   if [[ "$confirmation" != "yes" ]]; then
       echo "STOP! Do not proceed until SSH key authentication works!"
       exit 1
   fi
   ```

**Safety Checks:**
- Create ~/.ssh with correct permissions (700)
- Set authorized_keys permissions (600)
- Keep root access as backup during testing
- Require manual confirmation that key auth works

**Critical Files:**
- /home/sleszugreen/.ssh/authorized_keys
- /root/.ssh/authorized_keys (emergency backup)

**User Action Required:**
1. Generate SSH key on desktop (detailed instructions provided)
2. Copy public key to Proxmox (paste when prompted)
3. Test SSH login with key (MANDATORY before continuing)
4. Keep old SSH session open as backup

---

### Phase 4: Remote Access Test #1 (MANDATORY CHECKPOINT)
**Purpose:** Verify all remote access methods work before proceeding

#### Manual Testing Checklist:

**DO NOT PROCEED until ALL tests pass!**

1. **SSH Key Authentication Test:**
   - [ ] Can SSH from desktop (192.168.99.6) using key: `ssh sleszugreen@192.168.40.60`
   - [ ] Login works WITHOUT password
   - [ ] Can run sudo commands

2. **Proxmox Web UI Test:**
   - [ ] Can access https://192.168.40.60:8006 in browser
   - [ ] Can login with sleszugreen account
   - [ ] Dashboard loads correctly
   - [ ] Can navigate all sections

3. **Web UI Shell Test:**
   - [ ] Click on "ugreen" node in left sidebar
   - [ ] Click "Shell" button at top
   - [ ] Shell opens in browser window
   - [ ] Can type commands and see output
   - [ ] Can run `sudo -l` to verify sudo access

4. **Keep Multiple Sessions Open:**
   - [ ] Have at least 2 SSH terminals open to Proxmox
   - [ ] Have Web UI open in browser
   - [ ] Have Web UI Shell ready as backup

**If ANY test fails, STOP and troubleshoot before continuing!**

---

### PHASE B: SECURITY HARDENING (BEFORE MOVING BOX)

---

### Phase 5: System Updates & Security Tools
**Purpose:** Install all required security packages

#### Script 5: `05-system-update.sh`
**Location:** `/root/proxmox-hardening/05-system-update.sh`

**Actions:**
1. Update package lists: `apt update`
2. Upgrade all packages: `apt full-upgrade -y`
3. Install security tools:
   - fail2ban (intrusion prevention)
   - unattended-upgrades (automatic security updates)
   - apt-listchanges (if not installed)
   - needrestart (detect service restarts needed)
   - logwatch (log monitoring)
4. Configure unattended-upgrades:
   - Enable automatic security updates
   - Configure for Debian and Proxmox repos
   - Set auto-reboot time (3 AM recommended)
   - Email notifications via ntfy.sh webhook
5. Clean up old packages: `apt autoremove -y`
6. Display installed versions

**Configuration Files:**
- /etc/apt/apt.conf.d/50unattended-upgrades
- /etc/apt/apt.conf.d/20auto-upgrades

**Safety Checks:**
- Verify adequate disk space before upgrade
- Log all package changes
- Create restoration point

---

### Phase 4: Firewall Configuration (Proxmox Native)
**Purpose:** Lock down network access to trusted IPs only

#### Script 4: `03-firewall-setup.sh`
**Location:** `/root/proxmox-hardening/03-firewall-setup.sh`

**Actions:**
1. Configure Proxmox datacenter firewall:
   ```bash
   # Create /etc/pve/firewall/cluster.fw
   ```

2. Firewall Rules (in order):
   ```
   [OPTIONS]
   enable: 1
   policy_in: DROP
   policy_out: ACCEPT

   [RULES]
   # SSH from trusted desktop
   IN ACCEPT -source 192.168.99.6 -p tcp -dport 22022 -log nolog

   # Proxmox Web UI from trusted desktop
   IN ACCEPT -source 192.168.99.6 -p tcp -dport 8006 -log nolog

   # ICMP (ping) for network diagnostics
   IN ACCEPT -p icmp -log nolog

   # Localhost communication
   IN ACCEPT -source 127.0.0.1 -log nolog

   # Allow established connections
   IN ACCEPT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED

   # Proxmox Cluster Communication (if clustering)
   # IN ACCEPT -source 192.168.40.0/24 -p tcp -dport 5405:5412 -log nolog
   # IN ACCEPT -source 192.168.40.0/24 -p udp -dport 5405:5412 -log nolog

   # Drop everything else and log
   IN DROP -log warning
   ```

3. Test firewall rules before enabling
4. Enable Proxmox firewall:
   ```bash
   systemctl enable pve-firewall
   systemctl restart pve-firewall
   ```
5. Display active rules: `pve-firewall status`

**Note for Future Netbird Access:**
- After Netbird installation, add rule:
  ```
  # Netbird VPN access
  IN ACCEPT -source 100.64.0.0/10 -p tcp -dport 22022 -log nolog
  IN ACCEPT -source 100.64.0.0/10 -p tcp -dport 8006 -log nolog
  ```

**Critical Files:**
- /etc/pve/firewall/cluster.fw (main rules)
- /etc/pve/firewall/HOSTNAME.fw (host-specific rules)

**Safety Checks:**
- Display rules before applying
- Require manual confirmation
- Keep existing session open (won't be killed)
- Test connectivity from 192.168.99.6
- Provide emergency disable command

**Emergency Rollback:**
```bash
# If locked out via console:
systemctl stop pve-firewall
rm /etc/pve/firewall/cluster.fw
```

---

### Phase 5: SSH Hardening
**Purpose:** Secure SSH with non-standard port and key-only authentication

#### Script 5: `04-ssh-harden.sh`
**Location:** `/root/proxmox-hardening/04-ssh-harden.sh`

**Actions:**
1. Verify SSH key authentication is working (check from Phase 2)
2. Backup current SSH config
3. Modify /etc/ssh/sshd_config:
   ```bash
   # Change port
   Port 22022

   # Disable root login
   PermitRootLogin no

   # Force key-based authentication
   PubkeyAuthentication yes
   PasswordAuthentication no
   ChallengeResponseAuthentication no

   # Security hardening
   MaxAuthTries 3
   MaxSessions 5
   LoginGraceTime 60

   # Session timeouts
   ClientAliveInterval 300
   ClientAliveCountMax 2

   # Disable dangerous features
   X11Forwarding no
   PermitEmptyPasswords no
   PermitUserEnvironment no

   # Only allow specific user
   AllowUsers sleszugreen

   # Use strong crypto
   Protocol 2
   Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
   MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
   KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
   ```

4. Test SSH configuration: `sshd -t`
5. Display what changed
6. **Restart SSH service:** `systemctl restart sshd`
7. **Test new connection** (in parallel terminal):
   ```bash
   ssh -p 22022 sleszugreen@192.168.40.60
   ```

**Critical Files:**
- /etc/ssh/sshd_config

**Safety Checks:**
- Verify SSH keys work BEFORE running this
- Keep current SSH session open (won't disconnect existing sessions)
- Test configuration syntax before applying
- Display test command for user
- Require manual confirmation that new connection works

**Emergency Rollback:**
```bash
# If locked out via console:
cp /root/proxmox-hardening/backups/sshd_config.backup /etc/ssh/sshd_config
systemctl restart sshd
```

**Post-Script User Action:**
- Open NEW terminal and test: `ssh -p 22022 sleszugreen@192.168.40.60`
- Confirm working before closing old session
- Update ~/.ssh/config on desktop:
  ```
  Host ugreen proxmox
      HostName 192.168.40.60
      Port 22022
      User sleszugreen
      IdentityFile ~/.ssh/id_rsa
  ```

---

### Phase 6: Fail2Ban Setup
**Purpose:** Protect against brute-force attacks

#### Script 6: `05-fail2ban-setup.sh`
**Location:** `/root/proxmox-hardening/05-fail2ban-setup.sh`

**Actions:**
1. Install fail2ban (if not done in Phase 3)
2. Create jail configuration: `/etc/fail2ban/jail.local`
   ```ini
   [DEFAULT]
   bantime = 3600
   findtime = 600
   maxretry = 3
   ignoreip = 127.0.0.1/8 192.168.99.6

   [sshd]
   enabled = true
   port = 22022
   filter = sshd
   logpath = /var/log/auth.log
   maxretry = 3
   bantime = 7200

   [proxmox]
   enabled = true
   port = https,http,8006
   filter = proxmox
   logpath = /var/log/daemon.log
   maxretry = 3
   bantime = 3600
   ```

3. Create Proxmox filter: `/etc/fail2ban/filter.d/proxmox.conf`
   ```ini
   [Definition]
   failregex = pvedaemon\[.*authentication failure; rhost=<HOST>
   ignoreregex =
   ```

4. Configure ntfy.sh notifications for bans:
   - Create action script: `/etc/fail2ban/action.d/ntfy.conf`
   - Webhook URL: https://ntfy.sh/proxmox-security-alerts

5. Enable and start fail2ban:
   ```bash
   systemctl enable fail2ban
   systemctl restart fail2ban
   ```

6. Display fail2ban status:
   ```bash
   fail2ban-client status
   fail2ban-client status sshd
   fail2ban-client status proxmox
   ```

**Critical Files:**
- /etc/fail2ban/jail.local
- /etc/fail2ban/filter.d/proxmox.conf
- /etc/fail2ban/action.d/ntfy.conf

**Safety Checks:**
- Add trusted IP (192.168.99.6) to ignoreip
- Test jail configuration: `fail2ban-client -t`
- Don't ban yourself during testing

**Testing Fail2Ban:**
```bash
# From another IP (not 192.168.99.6):
# Try to SSH with wrong password 3 times
# Should get banned for 2 hours
```

---

### Phase 7: HTTPS Certificate for Web UI (CRITICAL)
**Purpose:** Secure Proxmox Web UI with proper SSL certificate

#### Script 7: `07-https-certificate.sh`
**Location:** `/root/proxmox-hardening/07-https-certificate.sh`

**Actions:**

**Option A: Self-Signed Certificate (For Local Network - RECOMMENDED)**

1. Generate new self-signed certificate with proper details:
   ```bash
   openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
     -keyout /etc/pve/local/pve-ssl.key \
     -out /etc/pve/local/pve-ssl.pem \
     -subj "/C=PL/ST=Warsaw/L=Warsaw/O=Homelab/OU=Proxmox/CN=ugreen.local" \
     -addext "subjectAltName=DNS:ugreen.local,DNS:ugreen,IP:192.168.40.60"
   ```

2. Set correct permissions:
   ```bash
   chmod 600 /etc/pve/local/pve-ssl.key
   chmod 644 /etc/pve/local/pve-ssl.pem
   ```

3. Restart Proxmox proxy:
   ```bash
   systemctl restart pveproxy
   ```

4. Test certificate:
   ```bash
   openssl s_client -connect 192.168.40.60:8006 -showcerts
   ```

**Option B: Let's Encrypt Certificate (If Have Public Domain)**

*Only if you have a public domain pointing to your network*

1. Install certbot:
   ```bash
   apt install certbot -y
   ```

2. Stop pveproxy temporarily:
   ```bash
   systemctl stop pveproxy
   ```

3. Obtain certificate:
   ```bash
   certbot certonly --standalone \
     -d your-domain.com \
     --agree-tos \
     --email your-email@example.com
   ```

4. Link certificate to Proxmox:
   ```bash
   ln -sf /etc/letsencrypt/live/your-domain.com/fullchain.pem /etc/pve/local/pve-ssl.pem
   ln -sf /etc/letsencrypt/live/your-domain.com/privkey.pem /etc/pve/local/pve-ssl.key
   ```

5. Set up automatic renewal:
   ```bash
   echo "0 0 * * * root certbot renew --post-hook 'systemctl restart pveproxy'" > /etc/cron.d/certbot-proxmox
   ```

6. Restart pveproxy:
   ```bash
   systemctl start pveproxy
   ```

**Option C: Internal CA Certificate (For Multiple Devices)**

*If you want to create your own Certificate Authority for homelab*

1. Create CA key and certificate:
   ```bash
   # Create CA
   openssl genrsa -out /root/homelab-ca.key 4096
   openssl req -x509 -new -nodes -key /root/homelab-ca.key -sha256 -days 3650 \
     -out /root/homelab-ca.crt \
     -subj "/C=PL/ST=Warsaw/L=Warsaw/O=Homelab/OU=CA/CN=Homelab Root CA"
   ```

2. Create Proxmox certificate signed by CA:
   ```bash
   # Generate CSR
   openssl req -new -nodes -newkey rsa:4096 \
     -keyout /etc/pve/local/pve-ssl.key \
     -out /tmp/proxmox.csr \
     -subj "/C=PL/ST=Warsaw/L=Warsaw/O=Homelab/OU=Proxmox/CN=ugreen.local"

   # Sign with CA
   openssl x509 -req -in /tmp/proxmox.csr -CA /root/homelab-ca.crt \
     -CAkey /root/homelab-ca.key -CAcreateserial \
     -out /etc/pve/local/pve-ssl.pem -days 365 -sha256 \
     -extfile <(printf "subjectAltName=DNS:ugreen.local,DNS:ugreen,IP:192.168.40.60")
   ```

3. Import CA to browser/desktop (homelab-ca.crt)

4. Restart pveproxy:
   ```bash
   systemctl restart pveproxy
   ```

**Recommended Approach:**
- **For local network only:** Option A (Self-Signed) - Simplest, works immediately
- **If have public domain:** Option B (Let's Encrypt) - Free, auto-renewing, trusted
- **For multiple homelab devices:** Option C (Internal CA) - Best for homelab, reusable

**Script will ask user which option to use.**

**Critical Files:**
- /etc/pve/local/pve-ssl.key (private key)
- /etc/pve/local/pve-ssl.pem (certificate)
- /root/homelab-ca.crt (if using Option C)

**Benefits:**
- ✅ Reduces browser security warnings (Options B/C)
- ✅ Professional SSL setup
- ✅ Valid for 10 years (Option A) or auto-renewing (Option B)
- ✅ Encrypted web traffic

**Post-Setup:**
- Access Proxmox at: https://ugreen.local:8006 or https://192.168.40.60:8006
- Browser may still warn for self-signed (Option A) - this is normal for local network
- For Options B/C, no browser warnings

---

### Phase 8: Proxmox Backup Integration (OPTIONAL)
**Purpose:** Set up automated VM/container backups

#### Script 8: `08-proxmox-backup.sh`
**Location:** `/root/proxmox-hardening/08-proxmox-backup.sh`

**This phase is OPTIONAL - only run if you have:**
- Proxmox Backup Server (PBS) installed elsewhere
- External storage for backups (NAS, USB drive, etc.)
- Want to configure automated backups now

**Option A: Proxmox Backup Server (PBS) Integration**

*If you have PBS running on another machine*

1. Add PBS as backup storage in Proxmox:
   ```bash
   # Via Web UI: Datacenter > Storage > Add > Proxmox Backup Server
   # OR via CLI:
   pvesm add pbs backup-server \
     --server pbs.yourdomain.com \
     --datastore backups \
     --username backup@pbs \
     --password 'your-password' \
     --fingerprint 'PBS-fingerprint'
   ```

2. Create backup job:
   ```bash
   # Via Web UI: Datacenter > Backup > Add
   # Schedule: Daily at 2 AM
   # Retention: Keep last 7 daily backups
   ```

3. Test backup:
   ```bash
   vzdump --storage backup-server --mode snapshot --compress zstd
   ```

**Option B: Local/NAS Storage Backup**

*If using NFS/CIFS share for backups*

1. Create mount point:
   ```bash
   mkdir -p /mnt/backups
   ```

2. Mount NAS share (example for NFS):
   ```bash
   # Add to /etc/fstab:
   nas.local:/volume1/proxmox-backups /mnt/backups nfs defaults 0 0

   # Mount:
   mount /mnt/backups
   ```

3. Add as backup storage:
   ```bash
   # Via Web UI: Datacenter > Storage > Add > Directory
   # Or via CLI:
   pvesm add dir local-backups \
     --path /mnt/backups \
     --content backup \
     --maxfiles 7
   ```

4. Create backup schedule:
   ```bash
   # Via Web UI: Datacenter > Backup > Add
   # Or create vzdump job manually
   ```

**Option C: USB Drive Backup**

*If using external USB drive*

1. Identify USB drive:
   ```bash
   lsblk
   fdisk -l
   ```

2. Format and mount (if needed):
   ```bash
   mkfs.ext4 /dev/sdX1  # Replace sdX1 with your device
   mkdir -p /mnt/usb-backup
   mount /dev/sdX1 /mnt/usb-backup
   ```

3. Add to fstab:
   ```bash
   # Get UUID:
   blkid /dev/sdX1

   # Add to /etc/fstab:
   UUID=your-uuid /mnt/usb-backup ext4 defaults 0 0
   ```

4. Add as backup storage (same as Option B)

**Backup Strategy Recommendations:**

1. **3-2-1 Rule:**
   - 3 copies of data
   - 2 different storage types
   - 1 offsite copy

2. **Backup Schedule:**
   - VMs: Daily at 2 AM
   - Containers: Daily at 3 AM
   - Full Proxmox config: Weekly

3. **Retention Policy:**
   - Keep last 7 daily backups
   - Keep last 4 weekly backups
   - Keep last 3 monthly backups

4. **What to Backup:**
   - All VMs (snapshot mode if possible)
   - All containers
   - Proxmox configuration: `/etc/pve/`
   - Custom scripts: `/root/`

**Backup Proxmox Host Configuration:**

```bash
# Create backup script:
cat > /root/backup-proxmox-config.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/mnt/backups/proxmox-config"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR/$DATE
cp -r /etc/pve $BACKUP_DIR/$DATE/
cp -r /root/proxmox-hardening $BACKUP_DIR/$DATE/
cp /etc/network/interfaces $BACKUP_DIR/$DATE/
cp /etc/hosts $BACKUP_DIR/$DATE/
dpkg --get-selections > $BACKUP_DIR/$DATE/packages.list

tar czf $BACKUP_DIR/proxmox-config-$DATE.tar.gz -C $BACKUP_DIR $DATE
rm -rf $BACKUP_DIR/$DATE

# Keep only last 10 config backups
ls -t $BACKUP_DIR/*.tar.gz | tail -n +11 | xargs -r rm

echo "Backup complete: proxmox-config-$DATE.tar.gz"
EOF

chmod +x /root/backup-proxmox-config.sh
```

**Schedule config backup (weekly):**
```bash
echo "0 4 * * 0 root /root/backup-proxmox-config.sh" > /etc/cron.d/proxmox-config-backup
```

**Critical Files:**
- /etc/pve/ (Proxmox configuration)
- /etc/fstab (backup storage mounts)
- /root/backup-proxmox-config.sh (config backup script)

**Benefits:**
- ✅ Automated VM/container backups
- ✅ Easy restoration if something goes wrong
- ✅ Protection against hardware failure
- ✅ Configuration versioning

**Post-Setup:**
- Test restore procedure with a test VM/container
- Verify backups are running successfully
- Check backup logs: /var/log/vzdump/
- Monitor backup storage space

**User Question:**
- Do you have Proxmox Backup Server or NAS for backups?
- If yes, provide details (PBS IP, NAS share path, etc.)
- If no, this phase can be skipped for now and added later

---

### Phase 9: Notification Setup (ntfy.sh)
**Purpose:** Real-time security alerts without exposing email credentials

#### Script 9: `09-notification-setup.sh`
**Location:** `/root/proxmox-hardening/09-notification-setup.sh`

**Actions:**
1. Set up ntfy.sh topic: `proxmox-security-alerts-ugreen`
   - Topic URL: https://ntfy.sh/proxmox-security-alerts-ugreen

2. Install ntfy CLI tool:
   ```bash
   wget -O /usr/local/bin/ntfy https://github.com/binwiederhier/ntfy/releases/latest/download/ntfy_linux_amd64
   chmod +x /usr/local/bin/ntfy
   ```

3. Create notification helper script: `/usr/local/bin/send-security-alert.sh`
   ```bash
   #!/bin/bash
   NTFY_TOPIC="proxmox-security-alerts-ugreen"
   MESSAGE="$1"
   PRIORITY="${2:-default}"

   curl -H "Title: Proxmox Security Alert" \
        -H "Priority: $PRIORITY" \
        -H "Tags: warning" \
        -d "$MESSAGE" \
        https://ntfy.sh/$NTFY_TOPIC
   ```

4. Integrate with fail2ban (already done in Phase 6)

5. Create test notification:
   ```bash
   /usr/local/bin/send-security-alert.sh "Proxmox hardening complete!" "low"
   ```

6. Configure unattended-upgrades to use ntfy:
   - Modify /etc/apt/apt.conf.d/50unattended-upgrades
   - Add post-upgrade hook to send notification

**User Setup Required:**
1. Install ntfy app on phone/desktop:
   - Android: https://play.google.com/store/apps/details?id=io.heckel.ntfy
   - iOS: https://apps.apple.com/app/ntfy/id1625396347
   - Desktop: https://ntfy.sh/app

2. Subscribe to topic: `proxmox-security-alerts-ugreen`

**Notification Events:**
- Fail2ban bans/unbans
- SSH login attempts (optional)
- System updates available/installed
- Security patches applied
- Firewall changes

**Alternative:**
- If user prefers Telegram, create bot setup instructions

---

### Phase 8: Additional Hardening
**Purpose:** Extra security measures and best practices

#### Script 8: `07-additional-hardening.sh`
**Location:** `/root/proxmox-hardening/07-additional-hardening.sh`

**Actions:**

1. **Disable unnecessary services:**
   ```bash
   # Check what's running
   systemctl list-units --type=service --state=running

   # Disable if not needed:
   # systemctl disable rpcbind (needed for NFS)
   # systemctl disable postfix (unless using local mail)
   ```

2. **Configure secure shared memory:**
   ```bash
   # Add to /etc/fstab:
   none /run/shm tmpfs defaults,ro,noexec,nosuid 0 0
   ```

3. **Enable kernel security parameters:**
   Create `/etc/sysctl.d/99-proxmox-hardening.conf`:
   ```ini
   # IP Forwarding (needed for Proxmox VMs/containers)
   net.ipv4.ip_forward = 1

   # SYN flood protection
   net.ipv4.tcp_syncookies = 1
   net.ipv4.tcp_max_syn_backlog = 2048

   # IP spoofing protection
   net.ipv4.conf.all.rp_filter = 1
   net.ipv4.conf.default.rp_filter = 1

   # Ignore ICMP redirects
   net.ipv4.conf.all.accept_redirects = 0
   net.ipv4.conf.default.accept_redirects = 0
   net.ipv4.conf.all.secure_redirects = 0
   net.ipv4.conf.default.secure_redirects = 0

   # Ignore ICMP ping requests (optional)
   # net.ipv4.icmp_echo_ignore_all = 1

   # Log suspicious packets
   net.ipv4.conf.all.log_martians = 1
   net.ipv4.conf.default.log_martians = 1

   # Disable source packet routing
   net.ipv4.conf.all.accept_source_route = 0
   net.ipv4.conf.default.accept_source_route = 0

   # Protect against SYN flood attacks
   net.ipv4.tcp_synack_retries = 2
   ```
   Apply: `sysctl -p /etc/sysctl.d/99-proxmox-hardening.conf`

4. **Set up log monitoring:**
   - Install logwatch: `apt install logwatch`
   - Configure daily reports via ntfy.sh
   - Key logs to monitor:
     - /var/log/auth.log (SSH attempts)
     - /var/log/daemon.log (Proxmox auth)
     - /var/log/fail2ban.log (bans)

5. **Configure AppArmor (already installed):**
   ```bash
   aa-status  # Check status
   systemctl enable apparmor
   ```

6. **Password policies for local accounts:**
   ```bash
   # Install password quality checker
   apt install libpam-pwquality

   # Configure /etc/security/pwquality.conf:
   minlen = 12
   dcredit = -1
   ucredit = -1
   lcredit = -1
   ocredit = -1
   ```

7. **Secure /tmp directory:**
   ```bash
   # Add to /etc/fstab:
   tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0
   ```

8. **Disable IPv6 (if not used):**
   ```bash
   # Add to /etc/sysctl.conf:
   net.ipv6.conf.all.disable_ipv6 = 1
   net.ipv6.conf.default.disable_ipv6 = 1
   ```

**Critical Files:**
- /etc/sysctl.d/99-proxmox-hardening.conf
- /etc/fstab
- /etc/security/pwquality.conf

---

### Phase 9: Monitoring & Logging
**Purpose:** Detect and track security events

#### Script 9: `08-monitoring-setup.sh`
**Location:** `/root/proxmox-hardening/08-monitoring-setup.sh`

**Actions:**

1. **Set up login notifications:**
   Create `/etc/profile.d/ssh-login-notify.sh`:
   ```bash
   #!/bin/bash
   if [ -n "$SSH_CLIENT" ]; then
       IP=$(echo $SSH_CLIENT | awk '{print $1}')
       /usr/local/bin/send-security-alert.sh \
           "SSH Login: User $USER from $IP on $(hostname)" \
           "low"
   fi
   ```

2. **Configure auditd (system audit):**
   ```bash
   apt install auditd

   # Add audit rules in /etc/audit/rules.d/proxmox.rules:
   # Monitor SSH config changes
   -w /etc/ssh/sshd_config -p wa -k ssh_config

   # Monitor firewall changes
   -w /etc/pve/firewall/ -p wa -k firewall_config

   # Monitor user changes
   -w /etc/passwd -p wa -k user_changes
   -w /etc/shadow -p wa -k user_changes
   -w /etc/sudoers -p wa -k sudo_changes

   # Monitor failed login attempts
   -w /var/log/auth.log -p wa -k auth_log
   ```

3. **Create security dashboard script:** `/usr/local/bin/security-status.sh`
   ```bash
   #!/bin/bash
   echo "=== Proxmox Security Status ==="
   echo ""
   echo "Firewall Status:"
   pve-firewall status | head -5
   echo ""
   echo "Fail2Ban Status:"
   fail2ban-client status
   echo ""
   echo "Failed Login Attempts (last 24h):"
   grep "Failed password" /var/log/auth.log | grep "$(date +%b\ %e)" | wc -l
   echo ""
   echo "Active SSH Sessions:"
   who
   echo ""
   echo "Last 5 Logins:"
   last -5
   ```

4. **Set up daily security report:**
   Create cron job: `/etc/cron.daily/security-report`
   ```bash
   #!/bin/bash
   /usr/local/bin/security-status.sh > /tmp/security-report.txt
   /usr/local/bin/send-security-alert.sh \
       "$(cat /tmp/security-report.txt)" \
       "low"
   ```

**Critical Files:**
- /etc/profile.d/ssh-login-notify.sh
- /etc/audit/rules.d/proxmox.rules
- /usr/local/bin/security-status.sh
- /etc/cron.daily/security-report

---

### Phase 10: Verification & Testing
**Purpose:** Confirm all security measures are working

#### Script 10: `09-verification.sh`
**Location:** `/root/proxmox-hardening/09-verification.sh`

**Actions:**

1. **Check SSH hardening:**
   ```bash
   # Verify port 22022
   ss -tlnp | grep :22022

   # Verify root login disabled
   grep "^PermitRootLogin" /etc/ssh/sshd_config

   # Verify password auth disabled
   grep "^PasswordAuthentication" /etc/ssh/sshd_config
   ```

2. **Check firewall rules:**
   ```bash
   pve-firewall status
   pve-firewall compile
   iptables -L -n -v
   ```

3. **Check fail2ban:**
   ```bash
   fail2ban-client status
   fail2ban-client status sshd
   fail2ban-client status proxmox
   ```

4. **Check automatic updates:**
   ```bash
   systemctl status unattended-upgrades
   cat /etc/apt/apt.conf.d/20auto-upgrades
   ```

5. **Security audit:**
   ```bash
   # Check for rootkits
   apt install rkhunter
   rkhunter --update
   rkhunter --check --skip-keypress

   # Check for vulnerabilities
   apt install lynis
   lynis audit system
   ```

6. **Network scan (from desktop 192.168.99.6):**
   ```bash
   # Install nmap on desktop:
   nmap -p- 192.168.40.60

   # Should only show:
   # 22022/tcp open (SSH)
   # 8006/tcp open (Proxmox Web UI)
   ```

7. **Generate security report:**
   ```bash
   /usr/local/bin/security-status.sh
   ```

**Verification Checklist:**
- [ ] SSH accessible on port 22022 from 192.168.99.6
- [ ] SSH not accessible on port 22
- [ ] Root SSH login denied
- [ ] Password authentication disabled
- [ ] Firewall blocking all except 192.168.99.6
- [ ] Fail2ban active and protecting SSH + Proxmox
- [ ] Notifications working (ntfy.sh test successful)
- [ ] Automatic updates configured
- [ ] All backups created
- [ ] Security audit tools installed

**Generate Final Report:**
Create `/root/proxmox-hardening/SECURITY-REPORT.txt` with:
- All applied changes
- Current security posture
- Open ports
- Firewall rules
- Fail2ban jails
- Recommendations for ongoing maintenance

---

## Master Script: Complete Hardening Workflow

### Script: `00-master-hardening.sh`
**Location:** `/root/proxmox-hardening/00-master-hardening.sh`

**Purpose:** Run all hardening scripts in correct order with confirmations

```bash
#!/bin/bash
# Proxmox Hardening Master Script

SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"

scripts=(
    "00-pre-hardening-checks.sh"
    "01-ssh-key-setup.sh"
    "02-system-update.sh"
    "03-firewall-setup.sh"
    "04-ssh-harden.sh"
    "05-fail2ban-setup.sh"
    "06-notification-setup.sh"
    "07-additional-hardening.sh"
    "08-monitoring-setup.sh"
    "09-verification.sh"
)

for script in "${scripts[@]}"; do
    echo "=== Running $script ==="
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/$script" | tee -a "$LOG_FILE"
    else
        echo "Skipped $script"
    fi
done
```

---

## Additional Recommendations

### 1. Two-Factor Authentication (Future Enhancement)
- Install Google Authenticator PAM module
- Configure for SSH and Proxmox Web UI
- Backup codes for emergency access

### 2. Intrusion Detection System (Future)
- Install AIDE (Advanced Intrusion Detection Environment)
- Set up file integrity monitoring
- Daily integrity checks via cron

### 3. VPN Access via Netbird
- After Netbird installation, add firewall rules:
  ```
  IN ACCEPT -source 100.64.0.0/10 -p tcp -dport 22022
  IN ACCEPT -source 100.64.0.0/10 -p tcp -dport 8006
  ```

### 4. Backup Strategy
- Regular configuration backups to remote location
- Test restoration procedures
- Document emergency recovery steps

### 5. Security Maintenance Schedule
- **Daily:** Review fail2ban logs
- **Weekly:** Check security updates
- **Monthly:** Review firewall rules, audit logs, run lynis scan
- **Quarterly:** Review and update documentation

---

## Critical Files & Locations

### Configuration Files:
- `/etc/ssh/sshd_config` - SSH configuration
- `/etc/pve/firewall/cluster.fw` - Firewall rules
- `/etc/fail2ban/jail.local` - Fail2ban configuration
- `/etc/sysctl.d/99-proxmox-hardening.conf` - Kernel parameters
- `/root/.ssh/authorized_keys` - SSH keys (emergency)
- `~/.ssh/authorized_keys` - SSH keys (sleszugreen)

### Backup Location:
- `/root/proxmox-hardening/backups/` - All configuration backups

### Scripts Location:
- `/root/proxmox-hardening/` - All hardening scripts

### Logs:
- `/var/log/auth.log` - SSH authentication
- `/var/log/daemon.log` - Proxmox logs
- `/var/log/fail2ban.log` - Fail2ban activity
- `/root/proxmox-hardening/hardening.log` - Script execution log

---

## Emergency Recovery Procedures

### If Locked Out of SSH:

1. **Via Proxmox Web UI (https://192.168.40.60:8006):**
   - Login with sleszugreen
   - Open Shell via web interface
   - Run recovery commands

2. **Via Physical Console:**
   - Login as sleszugreen
   - Restore SSH config:
     ```bash
     sudo cp /root/proxmox-hardening/backups/sshd_config.backup /etc/ssh/sshd_config
     sudo systemctl restart sshd
     ```

3. **If Firewall Blocking:**
   - Via console:
     ```bash
     sudo systemctl stop pve-firewall
     sudo rm /etc/pve/firewall/cluster.fw
     ```

### Rollback Entire Hardening:
```bash
cd /root/proxmox-hardening
bash rollback.sh  # Will be created by pre-hardening script
```

---

## Execution Order

### PHASE A: Remote Access Foundation (BEFORE MOVING BOX!)

1. ✅ Run `00-repository-setup.sh` - **Fix Proxmox repos, remove "no subscription" popup**
2. ✅ Run `00.5-ntp-setup.sh` - **Configure time synchronization**
3. ✅ Run `01-pre-hardening-checks.sh` - **Create backups, verify Web UI access**
4. ✅ Run `02-smart-monitoring.sh` - **Set up disk health monitoring**
5. ✅ Run `03-ssh-key-setup.sh` - **CRITICAL: Set up SSH keys with detailed instructions**
6. ✅ **MANDATORY CHECKPOINT:** Complete Remote Access Test #1 (Phase 4)
   - Test SSH key login (MUST WORK!)
   - Test Proxmox Web UI access
   - Test Web UI Shell access
   - Keep multiple sessions open
7. ✅ **DO NOT PROCEED until ALL remote access tests pass!**

### PHASE B: Security Hardening (BEFORE MOVING BOX!)

8. ✅ Run `05-system-update.sh` - **Install security tools and update system**
9. ✅ Run `06-firewall-setup.sh` - **Configure firewall (test from 192.168.99.6 after!)**
10. ✅ **TEST FIREWALL:** Verify can still access SSH and Web UI from desktop
11. ✅ Run `07-https-certificate.sh` - **Set up proper SSL certificate (choose option)**
12. ✅ Run `08-proxmox-backup.sh` - **OPTIONAL: Configure backups if you have storage**
13. ✅ Run `XX-ssh-harden.sh` - **Change SSH port to 22022, disable passwords**
14. ✅ **CRITICAL TEST:** Open new terminal, test `ssh -p 22022 sleszugreen@192.168.40.60`
15. ✅ **DO NOT CLOSE OLD SESSION until new SSH port works!**
16. ✅ **MANDATORY CHECKPOINT:** Complete Remote Access Test #2
   - Test SSH on port 22022
   - Test Web UI still works
   - Test Web UI Shell still works
   - Verify firewall not blocking you

### 🚀 **BOX CAN NOW BE MOVED TO REMOTE LOCATION**

### PHASE C: Protection & Monitoring (CAN DO AFTER MOVING BOX)

17. ✅ Run `XX-fail2ban-setup.sh` - **Install fail2ban protection**
18. ✅ Run `XX-notification-setup.sh` - **Set up ntfy.sh alerts (install app first!)**
19. ✅ Run `XX-additional-hardening.sh` - **Kernel hardening, AppArmor, etc.**
20. ✅ Run `XX-monitoring-setup.sh` - **Set up logging and monitoring**
21. ✅ Run `XX-verification.sh` - **Final verification and security audit**

### PHASE D: Optional Enhancements (ANYTIME)

22. 🔧 Add Netbird firewall rules (after Netbird installation)
23. 🔧 Set up two-factor authentication (2FA)
24. 🔧 Configure intrusion detection (AIDE)
25. 🔧 Set up centralized logging

**CRITICAL REMINDERS:**
- ⚠️ Always keep 2+ SSH sessions open when making changes
- ⚠️ Always test new configuration before closing old sessions
- ⚠️ Proxmox Web UI Shell is your emergency backup access
- ⚠️ Complete BOTH mandatory checkpoints before moving box
- ⚠️ Physical console access should only be needed in worst-case scenario

**Recommended:** Use master script `00-master-hardening.sh` to run all phases in sequence with confirmations.

---

## Testing Procedures

### After Each Phase:

1. **After SSH Key Setup (Phase 2):**
   ```bash
   # From desktop (192.168.99.6):
   ssh sleszugreen@192.168.40.60
   # Should work without password
   ```

2. **After Firewall (Phase 4):**
   ```bash
   # From desktop (192.168.99.6):
   ssh sleszugreen@192.168.40.60  # Should work
   ping 192.168.40.60  # Should work

   # From other device (not 192.168.99.6):
   ssh sleszugreen@192.168.40.60  # Should timeout/refuse
   ```

3. **After SSH Hardening (Phase 5):**
   ```bash
   # From desktop (192.168.99.6):
   ssh -p 22022 sleszugreen@192.168.40.60  # Should work
   ssh -p 22 sleszugreen@192.168.40.60     # Should fail (port closed)
   ```

4. **After Fail2ban (Phase 6):**
   ```bash
   # Check status:
   sudo fail2ban-client status
   sudo fail2ban-client status sshd
   ```

5. **Final Verification (Phase 10):**
   ```bash
   # From desktop (192.168.99.6):
   nmap -p- 192.168.40.60
   # Should only show ports 22022 and 8006
   ```

---

## Success Criteria

Proxmox hardening is complete when:

**Phase A - Remote Access (BEFORE MOVING BOX):**
- ✅ Proxmox repositories configured (no subscription repo enabled)
- ✅ Time synchronization configured (NTP working)
- ✅ SMART disk monitoring active (health checks running)
- ✅ SSH key authentication working from desktop
- ✅ Proxmox Web UI accessible from desktop
- ✅ Web UI Shell works as emergency access method
- ✅ Multiple remote access methods verified and tested

**Phase B - Security Hardening (BEFORE MOVING BOX):**
- ✅ SSH accessible only via key on port 22022 from trusted IP
- ✅ Root SSH login disabled
- ✅ Password authentication disabled
- ✅ Firewall active and blocking all except trusted IP (192.168.99.6)
- ✅ HTTPS certificate configured (proper SSL for Web UI)
- ✅ Backup strategy configured (if applicable)
- ✅ All configurations backed up to /root/proxmox-hardening/backups/

**Phase C - Protection & Monitoring (AFTER MOVING BOX):**
- ✅ Fail2ban protecting SSH and Proxmox web UI
- ✅ Automatic security updates configured
- ✅ Real-time notifications working (ntfy.sh app installed and tested)
- ✅ Security monitoring and logging active
- ✅ Kernel hardening applied
- ✅ Verification script confirms all measures

**Overall:**
- ✅ User can access Proxmox via SSH (port 22022) from desktop
- ✅ User can access Proxmox Web UI (port 8006) from desktop
- ✅ Emergency Web UI Shell access works
- ✅ Emergency recovery procedures documented and tested
- ✅ Box can be safely moved to remote location without monitor/keyboard

---

## Post-Hardening Maintenance

### Weekly:
- Review `/var/log/auth.log` for suspicious activity
- Check fail2ban bans: `sudo fail2ban-client status`
- Verify automatic updates: `sudo cat /var/log/unattended-upgrades/unattended-upgrades.log`

### Monthly:
- Run security scan: `sudo lynis audit system`
- Review firewall rules for changes needed
- Test backup restoration procedures

### Quarterly:
- Update SSH keys if needed
- Review and update documentation
- Security audit with external tools

---

## Notes for Future Enhancements

1. **When Netbird is installed:**
   - Add Netbird subnet to firewall whitelist
   - Update fail2ban ignoreip
   - Test VPN access

2. **For clustered Proxmox:**
   - Add cluster communication rules to firewall
   - Allow ports 5405-5412 (TCP/UDP) from cluster IPs
   - Configure corosync encryption

3. **For production use:**
   - Consider hardware security module (HSM)
   - Implement certificate-based authentication
   - Set up centralized logging (syslog server)
   - Deploy IDS/IPS (Suricata/Snort)

---

## Questions for User Before Execution

1. ✅ Do you have physical/console access to UGREEN box? (In case of lockout)
2. ✅ Is 192.168.99.6 your current desktop IP? (Confirm before firewall setup)
3. ✅ Are you comfortable generating SSH keys on your desktop?
4. ⏳ Have you installed ntfy app on your phone? (For notifications)
5. ⏳ Do you want to proceed with all phases, or phase-by-phase?

---

## Estimated Timeline

**Phase A - Remote Access Foundation (BEFORE MOVING BOX):**
- Repository setup: 5 minutes
- NTP configuration: 3 minutes
- Pre-hardening checks + backups: 10 minutes
- SMART monitoring setup: 10 minutes
- SSH key setup + testing: 15 minutes
- Remote Access Test #1: 10 minutes
**Phase A Total:** ~55 minutes

**Phase B - Security Hardening (BEFORE MOVING BOX):**
- System updates: 15-20 minutes (depends on internet speed)
- Firewall setup + testing: 15 minutes
- HTTPS certificate: 10 minutes (Option A) or 30 minutes (Option B/C)
- Proxmox backup setup: 20 minutes (optional, if applicable)
- SSH hardening + testing: 20 minutes
- Remote Access Test #2: 10 minutes
**Phase B Total:** ~90-120 minutes

**Phase C - Protection & Monitoring (AFTER MOVING BOX):**
- Fail2ban setup: 15 minutes
- Notification setup: 10 minutes
- Additional hardening: 20 minutes
- Monitoring setup: 15 minutes
- Final verification: 15 minutes
**Phase C Total:** ~75 minutes

**TOTAL TIME:**
- **Before moving box (Phase A + B):** 145-175 minutes (2.5-3 hours)
- **After moving box (Phase C):** 75 minutes (1.25 hours)
- **Grand Total:** 220-250 minutes (3.5-4 hours)

**Note:** Times are estimates. Take breaks between phases, especially before/after critical tests. Better to go slow and be careful than rush and get locked out!

---

## Summary

This comprehensive plan will transform your Proxmox installation from a weak default configuration to a hardened, production-ready system **with bulletproof remote access**. The plan is specifically designed to ensure you can safely move the box to a remote location without monitor/keyboard access.

**Key Features of This Plan:**

**🔐 Security Hardening:**
- SSH hardened with keys-only authentication, non-standard port (22022)
- Firewall configured with strict IP whitelisting (192.168.99.6)
- Fail2ban protecting against brute-force attacks
- Root login disabled, password authentication disabled
- Kernel security hardening and AppArmor enabled
- HTTPS certificate for secure Web UI access

**🚀 Remote Access Priority:**
- Multiple verified remote access methods (SSH + Web UI + Web UI Shell)
- Two mandatory checkpoints to verify access before moving box
- Emergency recovery procedures via Proxmox Web UI
- Detailed testing at every step to prevent lockouts

**📊 Infrastructure Management:**
- Proxmox repositories properly configured (no subscription popup)
- Time synchronization (NTP) for accurate logs and certificates
- SMART disk monitoring with health alerts
- Automatic security updates configured
- Optional backup strategy (if you have storage)

**📱 Monitoring & Alerts:**
- Real-time security notifications via ntfy.sh (no email passwords!)
- Login notifications and failed attempt tracking
- Daily/weekly security reports
- SMART disk health alerts

**🔄 Safety Features:**
- All configuration files backed up before changes
- Rollback procedures documented for every phase
- Changes are reversible
- Multiple access methods ensure you can't get locked out
- Existing SSH sessions remain open during changes

**Phased Approach:**
1. **Phase A:** Establish and thoroughly test remote access (BEFORE moving box)
2. **Phase B:** Apply security hardening with continuous testing (BEFORE moving box)
3. **Phase C:** Add monitoring and protection layers (AFTER moving box)
4. **Phase D:** Optional enhancements when ready

After completion, your Proxmox will be:
- ✅ Secure against common attacks
- ✅ Accessible remotely from your desktop (192.168.99.6)
- ✅ Accessible via Netbird VPN (after you set it up)
- ✅ Monitored for security events and disk health
- ✅ Automatically updated with security patches
- ✅ Ready to be moved to remote location without physical access
- ✅ Production-ready for VMs and containers

**This plan prioritizes preventing lockouts while achieving maximum security.** Every step includes safety checks and testing procedures. You'll have multiple ways to access your system, and the box can be safely moved to a remote location after Phase B is complete.