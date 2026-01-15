#!/usr/bin/env bash
set -Eeuo pipefail

# Error trap
trap 'echo "ERROR on line $LINENO, exit code $?"' ERR

REMOTE_HOST="homelab"
PAYLOAD_SCRIPT="/tmp/samba_fix_payload_$(date +%s).sh"

echo "[*] Generating remote payload..."

# Create the script that will run on the HOMELAB SERVER
cat << 'EOF_PAYLOAD' > /tmp/payload_temp_$$.sh
#!/bin/bash
set -Eeuo pipefail

SMB_CONF="/etc/samba/smb.conf"
BACKUP_SUFFIX=$(date +%Y%m%d-%H%M%S)

echo "[Remote] Creating timestamped backup..."
cp "${SMB_CONF}" "${SMB_CONF}.bak.${BACKUP_SUFFIX}"
echo "  ✓ Backup: ${SMB_CONF}.bak.${BACKUP_SUFFIX}"

echo "[Remote] Applying Python fixes to Samba configuration..."
python3 << 'EOPY'
import re
import os

SMB_CONF = "/etc/samba/smb.conf"

# Read current config
with open(SMB_CONF, 'r') as f:
    content = f.read()

# Remove old [FilmsHomelab] section (from [FilmsHomelab] to just before next [SectionName])
content = re.sub(
    r'\[FilmsHomelab\].*?(?=\n\[|\Z)',
    '',
    content,
    flags=re.DOTALL
)

# Remove old [SeriesHomelab] section
content = re.sub(
    r'\[SeriesHomelab\].*?(?=\n\[|\Z)',
    '',
    content,
    flags=re.DOTALL
)

# Clean up excess blank lines (more than 2 consecutive newlines)
content = re.sub(r'\n\n\n+', '\n\n', content)

# Ensure file ends with single newline
content = content.rstrip() + '\n'

# Append corrected share blocks
corrected_shares = '''
# Films Collection
[FilmsHomelab]
   comment = Films Collection
   path = /Seagate-20TB-mirror/FilmsHomelab
   browseable = yes
   read only = no
   valid users = samba-homelab
   force user = samba-homelab
   force group = samba-homelab
   create mask = 0664
   directory mask = 0775

# Series Collection
[SeriesHomelab]
   comment = Series Collection
   path = /Seagate-20TB-mirror/SeriesHomelab
   browseable = yes
   read only = no
   valid users = samba-homelab
   force user = samba-homelab
   force group = samba-homelab
   create mask = 0664
   directory mask = 0775
'''

content = content + corrected_shares + '\n'

# Write updated config
with open(SMB_CONF, 'w') as f:
    f.write(content)

print("[✓] Configuration blocks updated")
EOPY

echo "[Remote] Validating Samba configuration..."
testparm -s "${SMB_CONF}" > /dev/null
echo "  ✓ Configuration is valid"

echo "[Remote] Restarting smbd and nmbd services..."
systemctl restart smbd nmbd
echo "  ✓ Services restarted successfully"

echo ""
echo "============================================"
echo "✓ SAMBA CONFIGURATION FIX COMPLETE"
echo "============================================"
echo "Backup location: ${SMB_CONF}.bak.${BACKUP_SUFFIX}"
echo "Updated shares:"
echo "  • [FilmsHomelab]  → forced to samba-homelab user"
echo "  • [SeriesHomelab] → forced to samba-homelab user"
echo ""
echo "Windows clients should now be able to access both shares."
echo "Test with: \\\\192.168.40.40\\FilmsHomelab"
EOF_PAYLOAD

# Store the temp file path
TEMP_PAYLOAD="/tmp/payload_temp_$$.sh"

# Copy payload to remote
echo "[*] Copying payload to ${REMOTE_HOST}..."
scp -q "${TEMP_PAYLOAD}" "${REMOTE_HOST}:${PAYLOAD_SCRIPT}"
rm "${TEMP_PAYLOAD}"

# Execute with interactive sudo (forces TTY for password prompt)
echo "[*] Executing remote fix on homelab..."
echo "    (You will be prompted for your sudo password - enter it once)"
echo ""
ssh -t "${REMOTE_HOST}" "chmod +x ${PAYLOAD_SCRIPT} && sudo ${PAYLOAD_SCRIPT} && rm ${PAYLOAD_SCRIPT}"

echo ""
echo "[✓] All done! Samba shares on homelab have been fixed."
