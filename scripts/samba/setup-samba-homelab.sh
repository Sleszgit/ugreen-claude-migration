#!/bin/bash
# Setup Samba for Windows 11 access to homelab backup storage
# Run from Proxmox host: sudo bash /nvme2tb/lxc102scripts/samba/setup-samba-homelab.sh
# Or from container: sudo bash ~/scripts/samba/setup-samba-homelab.sh

set -e

echo "========================================="
echo "HOMELAB - Samba Setup for BackupFrom918"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo:"
    echo "  sudo bash setup-samba-homelab.sh"
    exit 1
fi

# Backup original config if it exists
if [ -f /etc/samba/smb.conf ]; then
    if [ ! -f /etc/samba/smb.conf.backup ]; then
        cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
        echo "✓ Backed up original Samba config to /etc/samba/smb.conf.backup"
    fi
fi

# Install Samba
echo ""
echo "[1/7] Installing Samba packages..."
apt update -qq
apt install -y samba samba-common-bin > /dev/null 2>&1
echo "✓ Samba installed"

# Create Samba configuration
echo ""
echo "[2/7] Configuring SMB shares..."
cat > /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = WORKGROUP
   server string = Homelab Backup Storage
   security = user
   map to guest = never
   
   # Performance optimizations
   socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=65536 SO_SNDBUF=65536
   read raw = yes
   write raw = yes
   max xmit = 65535
   dead time = 15
   getwd cache = yes
   
   # Logging
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file

# 918 Backup Storage
[BackupFrom918]
   comment = Backup from 918 NAS
   path = /WD10TB/918backup2512
   browseable = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   valid users = samba-homelab
   force user = samba-homelab
   force group = samba-homelab
EOF

echo "✓ SMB configuration created"
echo "  - Share: BackupFrom918"
echo "  - Path: /WD10TB/918backup2512"
echo "  - User: samba-homelab"
echo "  - Access: Read-Write"

# Create samba-homelab user
echo ""
echo "[3/7] Creating samba-homelab user..."
if ! id "samba-homelab" &>/dev/null; then
    useradd -r -s /usr/sbin/nologin -d /nonexistent samba-homelab
    echo "✓ User 'samba-homelab' created"
else
    echo "✓ User 'samba-homelab' already exists"
fi

# Set Samba password
echo ""
echo "[4/7] Setting Samba password for 'samba-homelab'..."
smbpasswd -a samba-homelab
echo "✓ Samba password set"

# Fix file ownership
echo ""
echo "[5/7] Setting file permissions..."
chown -R samba-homelab:samba-homelab /WD10TB/918backup2512/
chmod -R 775 /WD10TB/918backup2512/
echo "✓ Ownership: samba-homelab"
echo "✓ Permissions: 775 (read-write)"

# Enable and start Samba
echo ""
echo "[6/7] Starting Samba services..."
systemctl enable smbd nmbd > /dev/null 2>&1
systemctl restart smbd nmbd
echo "✓ Samba services started and enabled"

# Check firewall
echo ""
echo "[7/7] Checking firewall..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "Firewall is active. Opening Samba ports..."
        ufw allow 137,138,139,445/tcp > /dev/null 2>&1
        ufw allow 137,138/udp > /dev/null 2>&1
        echo "✓ Firewall configured"
    else
        echo "✓ Firewall not active"
    fi
else
    echo "✓ UFW not installed"
fi

# Display connection info
echo ""
echo "========================================="
echo "✅ SAMBA SETUP COMPLETE!"
echo "========================================="
echo ""
echo "Windows 11 Connection Details:"
echo "================================"
echo "Server Address: \\\\192.168.40.40"
echo "Username: samba-homelab"
echo "Password: [the password you just set above]"
echo ""
echo "Share Details:"
echo "  UNC Path: \\\\192.168.40.40\\BackupFrom918"
echo "  Local Path: /WD10TB/918backup2512"
echo "  Access: Read-Write"
echo ""
echo "To test from Windows 11:"
echo "  1. Open File Explorer"
echo "  2. Type in address bar: \\\\192.168.40.40"
echo "  3. Enter username: samba-homelab"
echo "  4. Enter the password you set above"
echo "  5. You should see 'BackupFrom918' share"
echo ""
echo "To test from Linux/Mac:"
echo "  smbclient -L //192.168.40.40 -U samba-homelab"
echo ""
echo "Samba Logs:"
echo "  /var/log/samba/log.smbd"
echo "  /var/log/samba/log.nmbd"
echo ""
