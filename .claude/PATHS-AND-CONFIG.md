# Paths, Configuration & Sudoers

---

## Directory Structure (LXC 102)

**All confirmed paths in the container:**

### Project Directories
- `~/projects/` - Active projects
- `~/projects/ai-projects/` - AI-related work
- `~/projects/nas-transfer/` - NAS transfer automation
- `~/projects/proxmox-hardening/` - Proxmox security hardening

### Script Directories
- `~/scripts/` - Root directory for all utility scripts
  - `auto-update/` - Auto-update system scripts
  - `auto-update/.auto-update.sh` - Main auto-update script
  - `samba/` - Samba/Windows access scripts
  - `ssh/` - SSH utilities
  - `nas/` - NAS file copy scripts

### Documentation Directories
- `~/docs/` - All documentation
- `~/docs/claude-sessions/` - Session notes
- `~/docs/sessions/` - Alternative session location
- `~/docs/hardware/` - Hardware documentation

### Logs & Support
- `~/logs/` - Log files
- `~/logs/.auto-update.log` - Auto-update script log
- `~/.claude/` - Claude configuration directory
  - `CLAUDE.md` - Main configuration (this file's hub)
  - `PROXMOX-COMMANDS.md` - Command reference
  - `PATHS-AND-CONFIG.md` - This file
  - `TASK-EXECUTION.md` - Workflow documentation

### Configuration Files
- `~/.github-token` - GitHub API token (gitignored)
- `~/.bashrc` - Shell configuration
- `~/.ssh/` - SSH keys and config
- `~/.proxmox-api-token` - Proxmox cluster token (gitignored)
- `~/.proxmox-vm100-token` - VM 100 read-only token (gitignored)

### Shared Resources (LXC 102 Bind Mount)

**Purpose:** Shared directory accessible by both container AND Proxmox host

| From Container | From Proxmox Host | Configuration |
|---|---|---|
| `/mnt/lxc102scripts/` | `/nvme2tb/lxc102scripts/` | `mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts` |

**Organization within bind mount:**
```
/mnt/lxc102scripts/
├── enable-proxmox-api-access.sh     ← Firewall setup
├── test-api-from-container.sh       ← API verification
├── vm100ugreen/                     ← VM 100 UGREEN hardening
├── vm100homelab/                    ← VM 100 homelab scripts
├── transfer-scripts/                ← File transfer automation
└── utilities/                       ← Shared utilities
```

**Usage:**
```bash
# Create in container (using printf - avoids heredoc issues):
printf '#!/bin/bash\necho "test"\n' > /mnt/lxc102scripts/my-script.sh
chmod +x /mnt/lxc102scripts/my-script.sh

# Run from Proxmox host:
sudo bash /nvme2tb/lxc102scripts/my-script.sh

# Run from container:
bash /mnt/lxc102scripts/my-script.sh

# ℹ️ NOTE: Use printf or echo commands instead of heredoc (<<EOF)
# Heredoc breaks in nested shell contexts (e.g., sudo bash -c)
```

---

## Command Location Matrix

Identify your location by the shell prompt hostname:

| What | Location | Example | Hostname |
|------|----------|---------|----------|
| **Proxmox Management** | PROXMOX HOST | `sudo qm list` | `ugreen` |
| **Container Management** | PROXMOX HOST | `sudo pct status 102` | `ugreen` |
| **Package Updates** | IN CONTAINER | `apt update && apt upgrade` | `ugreen-ai-terminal` |
| **Claude Code** | IN CONTAINER | `npm update -g @anthropic-ai/claude-code` | `ugreen-ai-terminal` |
| **File Operations** | IN CONTAINER | `ls ~/docs/`, `cp file1 file2` | `ugreen-ai-terminal` |

---

## Sudoers Configuration (sleszugreen)

**General sudo access:**
```
User has full sudo access: (ALL : ALL) ALL
Requires password for most commands
```

**Passwordless (NOPASSWD) commands:**
```bash
sudo npm update -g @anthropic-ai/claude-code        ✅ Passwordless
sudo apt update                                     ✅ Passwordless
sudo apt upgrade -y                                 ✅ Passwordless
sudo apt autoremove -y                              ✅ Passwordless
```

**Commands requiring password:**
```bash
sudo pct <command>                  ⚠️ Requires password (Proxmox host commands)
sudo qm <command>                   ⚠️ Requires password
sudo pvesh <command>                ⚠️ Requires password
sudo systemctl <command>            ⚠️ Requires password
```

---

## Environment Variables & Sudo

**Sudo strips environment variables by default for security.**

**For apt commands with DEBIAN_FRONTEND:**
```bash
# This works (DEBIAN_FRONTEND is allowed for apt):
sudo apt upgrade -y

# Verification:
sudo -n npm list --depth=0            # Check passwordless works
```

---

## Direct Execution Rules (LXC 102)

**Execute DIRECTLY without asking (routine operations):**
- ✅ `apt update`, `apt upgrade`, `apt install`
- ✅ `npm update -g`, `npm install -g`
- ✅ `ls`, `cp`, `mkdir`, `rm`, `cat`, `grep`
- ✅ `git status`, `git diff`, `ls -la`
- ✅ `claude --version`, `uname -a`, `df -h`

**Commands REQUIRING approval first:**
- ❌ Proxmox: `sudo pct`, `sudo qm`, `sudo pvesh`
- ❌ Config changes: Editing `/etc/` files, systemd services
- ❌ Destructive: `rm -rf`, clearing logs, deleting data
- ❌ Multi-step operations with rollback needs

---

## File Permissions & Ownership

**Important directories:**
- Home directory: `drwxr-xr-x` (user:group = sleszugreen:sleszugreen)
- Scripts in bind mount: Should be executable after `chmod +x`
- Config files: `mode 600` for sensitive files (tokens, keys)

---

## Security Notes

**Files SAFE to share in chat:**
- ✅ SSH public keys (`.pub` files)
- ✅ Documentation, code snippets
- ✅ Configuration examples (with sensitive values removed)

**Files NEVER to share:**
- ❌ Private SSH keys (no `.pub` extension)
- ❌ Passwords, API tokens
- ❌ `~/.proxmox-api-token` or `~/.github-token`
- ❌ Anything in `.bashrc` containing secrets

---

## Testing Command Location

**Always verify your location before providing commands:**

```bash
# If prompt shows this:
sleszugreen@ugreen:~$           → PROXMOX HOST (use sudo pct, qm, pvesh)
sleszugreen@ugreen-ai-terminal:~$  → IN CONTAINER (use apt, npm, file ops)
```

If unsure which location a command runs in, check this file's **Command Location Matrix** above.
