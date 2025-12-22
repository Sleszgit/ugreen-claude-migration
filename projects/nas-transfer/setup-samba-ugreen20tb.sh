#!/bin/bash
# Setup Samba for Windows access to UGREEN 20TB storage
# Run on Proxmox host with: sudo bash setup-samba-ugreen20tb.sh
# Share name: ugreen20tb (points to /storage/Media with read/write access)

set -e

echo "========================================="
echo "UGREEN Samba Setup - Single Share"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo:"
    echo "  sudo bash setup-samba-ugreen20tb.sh"
    exit 1
fi

# Check if /storage/Media exists
if [ ! -d /storage/Media ]; then
    echo "ERROR: /storage/Media does not exist!"
    echo "This script must be run on the Proxmox host."
    exit 1
fi

# Install Samba
echo "[1/4] Installing Samba server..."
apt update -qq
apt install -y samba samba-common-bin > /dev/null 2>&1
echo "✓ Samba installed"

# Backup original config if it exists
if [ -f /etc/samba/smb.conf ] && [ ! -f /etc/samba/smb.conf.backup ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    echo "✓ Backed up existing Samba config to smb.conf.backup"
fi

# Create new Samba configuration
echo ""
echo "[2/4] Configuring SMB share..."
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

# Full Storage - All 20TB Content (read/write for Windows management)
[ugreen20tb]
   comment = UGREEN 20TB Mirrored Storage - All Media
   path = /storage/Media
   browseable = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   valid users = sleszugreen
   force user = sleszugreen
EOF

echo "✓ Samba configuration created"
echo "  Share name: ugreen20tb"
echo "  Path: /storage/Media"
echo "  Permissions: Read/Write"
echo "  User: sleszugreen"

# Set Samba password
echo ""
echo "[3/4] Setting Samba password for user 'sleszugreen'..."
echo "Enter a password for Windows access (can be different from Linux password):"
smbpasswd -a sleszugreen

# Enable and start Samba
echo ""
echo "[4/4] Starting Samba services..."
systemctl enable smbd nmbd > /dev/null 2>&1
systemctl restart smbd nmbd
echo "✓ Samba services started and enabled"

# Check firewall status
echo ""
echo "Checking firewall..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "Firewall detected. Opening Samba ports..."
        ufw allow Samba > /dev/null 2>&1
        echo "✓ Firewall configured for Samba"
    else
        echo "✓ Firewall not active"
    fi
else
    echo "✓ No firewall detected (ufw not installed)"
fi

# Display connection info
echo ""
echo "========================================="
echo "✅ SAMBA SETUP COMPLETE!"
echo "========================================="
echo ""
echo "Windows 11 Connection Details:"
echo "  Server Address: \\\\192.168.40.60"
echo "  Share Name: \\\\192.168.40.60\\ugreen20tb"
echo "  Username: sleszugreen"
echo "  Password: [the password you just set]"
echo ""
echo "What you'll see from Windows:"
echo "  - Movies918/ (1.5 TB)"
echo "  - Series918/ (435 GB)"
echo "  - 20251209backupsfrom918/ (3.8 TB)"
echo "  - [Other folders and files]"
echo ""
echo "Test connection from command line (Windows):"
echo "  net view \\\\192.168.40.60"
echo ""
echo "Or connect directly in Total Commander:"
echo "  \\\\192.168.40.60\\ugreen20tb"
echo ""
