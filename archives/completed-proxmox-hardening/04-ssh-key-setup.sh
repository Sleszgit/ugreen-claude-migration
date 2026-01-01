#!/bin/bash
#########################################################################
# Proxmox Hardening - Phase A Script 4
# SSH Key Authentication Setup
#
# Purpose: Set up SSH key-based authentication BEFORE disabling passwords
#          This is CRITICAL - must work before SSH hardening!
#
# Run as: sudo bash 04-ssh-key-setup.sh
#########################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Logging
SCRIPT_DIR="/root/proxmox-hardening"
LOG_FILE="$SCRIPT_DIR/hardening.log"
BACKUP_DIR="$SCRIPT_DIR/backups"

mkdir -p "$SCRIPT_DIR" "$BACKUP_DIR"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

important() {
    echo -e "${MAGENTA}[IMPORTANT]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   echo "Please run: sudo bash $0"
   exit 1
fi

section "SSH Key Authentication Setup"

log "Starting SSH key setup..."
log "This script will guide you through setting up key-based authentication"

# Get the actual user (not root)
REAL_USER=${SUDO_USER:-sleszugreen}
USER_HOME=$(eval echo ~$REAL_USER)

log "Target user: $REAL_USER"
log "User home directory: $USER_HOME"

# Display instructions for key generation
section "SSH Key Generation Instructions"

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║              SSH KEY GENERATION - DO THIS ON YOUR DESKTOP          ║
║                      (192.168.99.6)                                ║
╚════════════════════════════════════════════════════════════════════╝

SSH keys provide secure, password-free authentication. You'll need to
generate a key pair on your desktop computer first.

STEP 1: Check if you already have SSH keys
─────────────────────────────────────────────────────────────────────

On your DESKTOP (192.168.99.6), open a terminal and run:

    ls -la ~/.ssh/id_*

If you see files like:
  • id_rsa and id_rsa.pub      OR
  • id_ed25519 and id_ed25519.pub

You ALREADY HAVE KEYS! Skip to Step 3.

STEP 2: Generate new SSH keys (if you don't have them)
─────────────────────────────────────────────────────────────────────

On your DESKTOP, run ONE of these commands:

  🔐 OPTION A - Ed25519 (Recommended - Modern & Secure):

    ssh-keygen -t ed25519 -C "sleszugreen@ugreen-proxmox"

  🔐 OPTION B - RSA (If Ed25519 not supported):

    ssh-keygen -t rsa -b 4096 -C "sleszugreen@ugreen-proxmox"

When prompted:
  1. Press ENTER to accept default location (~/.ssh/id_ed25519)
  2. Enter a PASSPHRASE (recommended!) or press ENTER for none
     • Passphrase = extra security for your key
     • You'll type this when using the key, NOT the server password
  3. Confirm passphrase

STEP 3: Display your PUBLIC key
─────────────────────────────────────────────────────────────────────

On your DESKTOP, run:

    cat ~/.ssh/id_ed25519.pub

      OR (if you used RSA):

    cat ~/.ssh/id_rsa.pub

You'll see output like:

    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGj... sleszugreen@ugreen-proxmox

      OR

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACA... sleszugreen@ugreen-proxmox

Copy THE ENTIRE LINE (it's one long line starting with ssh-ed25519 or ssh-rsa)

═══════════════════════════════════════════════════════════════════════

EOF

important "Have you generated your SSH key on your desktop?"
echo ""
read -p "Press ENTER when you're ready to paste your public key..."

# Create .ssh directory for user
section "Preparing SSH Directory"

SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

log "Creating SSH directory: $SSH_DIR"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown $REAL_USER:$REAL_USER "$SSH_DIR"
log "✓ SSH directory created with correct permissions"

# Backup existing authorized_keys if it exists
if [[ -f "$AUTHORIZED_KEYS" ]]; then
    backup_name="authorized_keys.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$AUTHORIZED_KEYS" "$BACKUP_DIR/$backup_name"
    log "Backed up existing authorized_keys: $backup_name"
fi

# Collect SSH public key from user
section "Adding Your SSH Public Key"

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                   PASTE YOUR SSH PUBLIC KEY                        ║
╚════════════════════════════════════════════════════════════════════╝

Now paste your ENTIRE public key (from your desktop).
It should be ONE LONG LINE starting with:
  • ssh-ed25519 ...
  • ssh-rsa ...

Paste it below and press ENTER:

EOF

# Read the public key
read -r ssh_public_key

# Validate the key format
if [[ ! "$ssh_public_key" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ssh-dss) ]]; then
    error "Invalid SSH key format!"
    error "Key should start with: ssh-rsa, ssh-ed25519, etc."
    echo ""
    echo "What you entered:"
    echo "$ssh_public_key"
    echo ""
    error "Please run the script again and paste the correct public key"
    exit 1
fi

log "✓ SSH public key format validated"

# Extract key type
KEY_TYPE=$(echo "$ssh_public_key" | awk '{print $1}')
log "Key type: $KEY_TYPE"

# Add key to authorized_keys
log "Adding public key to authorized_keys..."

# Create or append to authorized_keys
touch "$AUTHORIZED_KEYS"
echo "$ssh_public_key" >> "$AUTHORIZED_KEYS"

# Set correct permissions
chmod 600 "$AUTHORIZED_KEYS"
chown $REAL_USER:$REAL_USER "$AUTHORIZED_KEYS"

log "✓ Public key added to $AUTHORIZED_KEYS"

# Also add to root as emergency backup
section "Creating Emergency Root Access"

ROOT_SSH_DIR="/root/.ssh"
ROOT_AUTHORIZED_KEYS="$ROOT_SSH_DIR/authorized_keys"

log "Adding your key to root account as emergency backup..."
mkdir -p "$ROOT_SSH_DIR"
chmod 700 "$ROOT_SSH_DIR"

touch "$ROOT_AUTHORIZED_KEYS"
if ! grep -qF "$ssh_public_key" "$ROOT_AUTHORIZED_KEYS"; then
    echo "$ssh_public_key" >> "$ROOT_AUTHORIZED_KEYS"
fi

chmod 600 "$ROOT_AUTHORIZED_KEYS"

log "✓ Emergency root access configured"
warn "Root SSH access will be disabled later in SSH hardening phase"
warn "This is just for safety during setup"

# Display testing instructions
section "Testing SSH Key Authentication"

IP_ADDRESS=$(hostname -I | awk '{print $1}')

cat << EOF
╔════════════════════════════════════════════════════════════════════╗
║                   TEST YOUR SSH KEY NOW!                           ║
║                    ⚠️  CRITICAL STEP  ⚠️                            ║
╚════════════════════════════════════════════════════════════════════╝

${RED}DO NOT CONTINUE until you verify SSH key authentication works!${NC}

STEP 1: Open a NEW terminal on your desktop (192.168.99.6)
         DO NOT close this session!

STEP 2: Test SSH key authentication:

    ssh $REAL_USER@$IP_ADDRESS

  Or with explicit key:

    ssh -i ~/.ssh/id_ed25519 $REAL_USER@$IP_ADDRESS

  (Use id_rsa if you generated RSA keys)

EXPECTED BEHAVIOR:
─────────────────────────────────────────────────────────────────────
✓ If you set a passphrase: You'll be asked for your KEY passphrase
✓ If no passphrase: You'll login immediately WITHOUT any password
✗ You should NOT be asked for the server password

If it asks for "$REAL_USER@$IP_ADDRESS's password":
  ❌ Key authentication is NOT working
  ❌ DO NOT CONTINUE - something is wrong
  ❌ Run this script again or check troubleshooting below

TROUBLESHOOTING:
─────────────────────────────────────────────────────────────────────
If key auth doesn't work:

1. Check your public key was copied correctly:
   cat $AUTHORIZED_KEYS

2. Check permissions:
   ls -la $SSH_DIR
   ls -la $AUTHORIZED_KEYS

3. Try SSH with verbose mode:
   ssh -vvv $REAL_USER@$IP_ADDRESS

4. Check SSH logs on server:
   sudo tail -f /var/log/auth.log

═══════════════════════════════════════════════════════════════════════

EOF

important "KEEP THIS TERMINAL OPEN as backup!"
echo ""

# Wait for user confirmation
while true; do
    read -p "Did SSH key authentication work? (yes/no/help): " test_result

    case $test_result in
        yes)
            log "✓ User confirmed SSH key authentication works"
            break
            ;;
        no)
            error "SSH key authentication not working!"
            echo ""
            echo "Let's troubleshoot..."
            echo ""
            echo "Your authorized_keys file contains:"
            cat "$AUTHORIZED_KEYS"
            echo ""
            echo "Permissions:"
            ls -la "$SSH_DIR"
            ls -la "$AUTHORIZED_KEYS"
            echo ""
            error "Please fix the issue before continuing"
            error "You can run this script again to re-add the key"
            exit 1
            ;;
        help)
            echo ""
            echo "Common issues:"
            echo ""
            echo "1. Wrong key copied:"
            echo "   - Make sure you copied id_ed25519.pub (not id_ed25519!)"
            echo "   - The .pub file is the PUBLIC key"
            echo ""
            echo "2. Permissions issue:"
            echo "   - Check: ls -la ~/.ssh/"
            echo "   - .ssh directory should be 700"
            echo "   - authorized_keys should be 600"
            echo ""
            echo "3. SELinux or AppArmor blocking:"
            echo "   - Check: sudo tail /var/log/auth.log"
            echo ""
            read -p "Press ENTER to try again..."
            ;;
        *)
            echo "Please answer 'yes', 'no', or 'help'"
            ;;
    esac
done

# Create SSH config helper for user's desktop
section "Creating SSH Config Helper"

SSH_CONFIG_HELPER="$SCRIPT_DIR/desktop-ssh-config.txt"

cat > "$SSH_CONFIG_HELPER" << EOF
╔════════════════════════════════════════════════════════════════════╗
║          SSH Config for Your Desktop (~/.ssh/config)               ║
╚════════════════════════════════════════════════════════════════════╝

Add this to your ~/.ssh/config on your desktop (192.168.99.6)
to make SSH access easier:

# Proxmox UGREEN
Host ugreen proxmox ugreen-proxmox
    HostName $IP_ADDRESS
    User $REAL_USER
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    # Or: IdentityFile ~/.ssh/id_rsa

Then you can simply type:

    ssh ugreen

Instead of:

    ssh $REAL_USER@$IP_ADDRESS

Note: Port will change to 22022 after SSH hardening phase!

EOF

log "✓ SSH config helper created: $SSH_CONFIG_HELPER"

cat "$SSH_CONFIG_HELPER"

# Summary
section "SSH Key Authentication Setup Complete"

echo ""
log "✓ SSH directory created with correct permissions"
log "✓ Your public key added to authorized_keys"
log "✓ Emergency root access configured (temporary)"
log "✓ SSH key authentication tested and working"
echo ""

log "Key information:"
echo "  • User: $REAL_USER"
echo "  • Key type: $KEY_TYPE"
echo "  • Location: $AUTHORIZED_KEYS"
echo ""

log "Next steps:"
echo "  1. Complete the rest of Phase A scripts"
echo "  2. In Phase B, SSH will be hardened (port 22022, keys-only)"
echo "  3. After hardening, password authentication will be disabled"
echo ""

warn "IMPORTANT: Keep multiple SSH sessions open during hardening!"
warn "If something goes wrong, you have backup access via:"
warn "  • Proxmox Web UI Shell (https://$IP_ADDRESS:8006)"
warn "  • Physical console (if available)"
echo ""

log "Backup saved to: $BACKUP_DIR"
log "SSH config helper: $SSH_CONFIG_HELPER"
echo ""

log "Script completed successfully!"
log "Next step: Run 05-remote-access-test-1.sh"

exit 0
