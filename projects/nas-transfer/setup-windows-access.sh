#!/bin/bash
# Setup Samba for Windows 11 access to UGREEN media
# Run with: sudo bash setup-windows-access.sh

set -e

echo "========================================="
echo "UGREEN NAS - Windows 11 SMB Setup"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo:"
    echo "  sudo bash setup-windows-access.sh"
    exit 1
fi

# Install Samba
echo "[1/5] Installing Samba server..."
apt update -qq
apt install -y samba samba-common-bin > /dev/null 2>&1
echo "✓ Samba installed"

# Backup original config
if [ ! -f /etc/samba/smb.conf.backup ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    echo "✓ Backed up original Samba config"
fi

# Create Samba configuration
echo ""
echo "[2/5] Configuring SMB shares..."
cat > /etc/samba/smb.conf << 'EOF'
[global]
   workgroup = WORKGROUP
   server string = UGREEN NAS
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

# Movies from 918 NAS (998 GB)
[Movies918]
   comment = Movies from 918 NAS
   path = /storage/Media/Movies918
   browseable = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   valid users = sleszugreen
   force user = sleszugreen

# TV Shows from 918 NAS (435 GB)
[Series918]
   comment = TV Shows from 918 NAS
   path = /storage/Media/Series918
   browseable = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   valid users = sleszugreen
   force user = sleszugreen

# Full Media folder (if you want access to everything)
[Media]
   comment = All Media Storage
   path = /storage/Media
   browseable = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   valid users = sleszugreen
   force user = sleszugreen
EOF

echo "✓ SMB shares configured:"
echo "  - Movies918 (/storage/Media/Movies918)"
echo "  - Series918 (/storage/Media/Series918)"
echo "  - Media (full /storage/Media)"

# Set Samba password
echo ""
echo "[3/5] Setting Samba password for user 'sleszugreen'..."
echo "Enter a password for Windows access (can be different from Linux password):"
smbpasswd -a sleszugreen

# Enable and start Samba
echo ""
echo "[4/5] Starting Samba services..."
systemctl enable smbd nmbd > /dev/null 2>&1
systemctl restart smbd nmbd
echo "✓ Samba services started and enabled"

# Check firewall status
echo ""
echo "[5/5] Checking firewall..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "Firewall detected. Opening Samba ports..."
        ufw allow Samba
        echo "✓ Firewall configured"
    else
        echo "✓ Firewall not active"
    fi
else
    echo "✓ No firewall detected (ufw not installed)"
fi

# Display connection info
echo ""
echo "========================================="
echo "✅ SETUP COMPLETE!"
echo "========================================="
echo ""
echo "Windows 11 Connection Details:"
echo "  Server Address: \\\\192.168.40.60"
echo "  Username: sleszugreen"
echo "  Password: [the password you just set]"
echo ""
echo "Available Shares:"
echo "  \\\\192.168.40.60\\Movies918  (998 GB)"
echo "  \\\\192.168.40.60\\Series918  (435 GB)"
echo "  \\\\192.168.40.60\\Media      (all media)"
echo ""
echo "Test connection:"
echo "  smbclient -L //192.168.40.60 -U sleszugreen"
echo ""
