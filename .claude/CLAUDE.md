# Claude Code Configuration - UGREEN Instance

**Device:** UGREEN DXP4800+ Proxmox (192.168.40.60)  
**Container:** LXC 102 (ugreen-ai-terminal)  
**User:** sleszugreen  
**Default Location:** LXC 102 (unless explicitly stated otherwise)

---

## 🎯 User Profile

**Skill Level:**
- NOT an IT professional - computer enthusiast learning homelab/self-hosting
- Explain technical concepts in plain language
- Don't assume knowledge of industry-standard tools

**Preferences:**
- **STRONGLY PREFER web UIs** over CLI tools
- Explain what commands do
- Show dashboards and logs for visibility
- Explain the "why" behind recommendations

---

## 📋 Response Requirements

**ALWAYS end EVERY response with token usage:**
```
📊 Tokens: X used / 200,000 budget (Y remaining) | Weekly: Z% used | Resets: [next reset date/time]
```

**Critical Defaults:**
- **DEFAULT LOCATION:** LXC 102 (ugreen-ai-terminal) on UGREEN
- Only use location prefixes ("ON PROXMOX HOST:", "ON WINDOWS:") when NOT in LXC 102
- Always identify your location by shell prompt hostname

---

## ⚠️ SSH & API Access (Status - 28 Dec 2025)

**UGREEN Infrastructure:**
- ❌ SSH container → Proxmox host: **NOT configured**
- ✅ **USE:** Proxmox API with tokens instead
  - UGREEN cluster: `~/.proxmox-api-token`
  - UGREEN VM 100: `~/.proxmox-vm100-token`

**Homelab Access (Session 45 - COMPLETED):**
- ✅ SSH homelab → UGREEN: **OPERATIONAL**
  - User: `ugreen-homelab-ssh` on homelab (192.168.40.40)
  - SSH key: UGREEN public key in authorized_keys
  - Firewall: Fixed (cluster.fw corrected)
  - Passwordless sudo: ✅ Configured for all Proxmox commands
  - Tested commands: pveversion, qm list, pct list, zpool list
  - See `docs/claude-sessions/SESSION-45-HOMELAB-SSH-COMPLETION.md` for details

**Available Commands from UGREEN via SSH:**
- `sudo qm list/status/create/delete` - VM management
- `sudo pct list/status/create/delete` - Container management
- `sudo pvesh get/set` - Proxmox API CLI
- `sudo pveum user/acl` - User/permission management
- `sudo zpool/zfs` - ZFS pool management
- `sudo systemctl` - Service management
- `sudo pveversion` - Version info

**API Setup Status:** ✅ Properly configured for UGREEN (25 Dec 2025)
→ See `PROXMOX-API-SETUP.md` for full details

---

## 📁 Script Placement (RIGID Rule)

**ALL scripts accessible by both container AND Proxmox host MUST use bind mount:**

```
Container path:    /mnt/lxc102scripts/scriptname.sh
Proxmox host path: /nvme2tb/lxc102scripts/scriptname.sh
Mount config:      mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts
```

**Rule:** Create in `/mnt/lxc102scripts/`, run from `/nvme2tb/lxc102scripts/` on host

→ See `PATHS-AND-CONFIG.md` for full directory structure

---

## 📖 Documentation Hub

| Topic | File | Content |
|-------|------|---------|
| **Commands** | `PROXMOX-COMMANDS.md` | pct, qm, pvesh, pveum syntax with examples |
| **Paths & Config** | `PATHS-AND-CONFIG.md` | Directory structure, sudoers, env vars |
| **VM Creation** | `VM-CREATION-GUIDE.md` | Best practices, cloud-init, verified configs |
| **Infrastructure** | `INFRASTRUCTURE.md` | Network, storage, Samba, hardware specs |
| **Task Execution** | `TASK-EXECUTION.md` | Workflows, accuracy standards, approval process |
| **Proxmox API** | `PROXMOX-API-SETUP.md` | Token setup, firewall config, troubleshooting |

---

## 🚀 Quick Commands

**LXC 102 (Execute directly, no approval needed):**
```bash
apt update && apt upgrade -y          # Update packages
npm update -g @anthropic-ai/claude-code  # Update Claude Code
ls ~/docs/                            # List documentation
```

**Proxmox Host (Ask first, I execute):**
```bash
sudo qm status 100                    # Query VM 100
sudo pct status 102                   # Query container 102
sudo pvesh get /nodes/ugreen/status   # Query node status
```

---

## ⚡ Proxmox Command Decision Tree (Active until API fully operational)

**BEFORE attempting ANY command, I check this list:**

**Commands that REQUIRE sudo (Proxmox management):**
- `qm` (VM control: create, start, stop, delete, config)
- `pct` (Container control: create, start, stop, delete, config)
- `pvesh` (Proxmox API via CLI - read/write operations)
- `pveum` (User and permission management)
- `zpool` (ZFS pool management)
- `zfs` (ZFS filesystem management)
- `pve-firewall` (Firewall management)
- Firewall config file edits (`/etc/pve/firewall/`)
- Any storage/mount operations

**Commands that DON'T need sudo (informational only):**
- `pveversion` (version info)
- `pvesh get` for read-only queries (when not restricted)
- Help flags (`--help`, `-h`)

**Decision Rule:**
- If it **controls/modifies** Proxmox infrastructure → `sudo` required
- If it **reads** or **queries** Proxmox state → Check if sudo needed; apply if uncertain

**My Behavior:**
1. Recognize Proxmox-only command in your request
2. Check if it needs sudo (using list above)
3. **STOP** - Do NOT attempt in LXC102
4. Ask for approval and show the command **with sudo already included**
5. Execute only after you approve

---

## 🔧 Command Approval Workflow

1. **Read-only operations** → Execute directly (no approval needed)
2. **System changes** → Show command → Get approval → I execute it
3. **Proxmox host operations** → Always ask first before executing
4. **Destructive operations** → Backup → Show command → Get approval → I execute

→ See `TASK-EXECUTION.md` for full workflow details

---

## ⚠️ System Reboot Safety Protocol

**CRITICAL RULE: Before ANY planned system reboot, always:**

1. **Save current session** - Document what was done in this session
2. **Commit to GitHub** - Push all changes and session notes to repository
3. **THEN execute reboot** - Only after steps 1-2 are complete

**Why this matters:**
- If reboot fails or causes unexpected issues, we have a documented record
- GitHub preserves the exact state before reboot for recovery
- Session history shows the complete sequence of changes
- Enables rapid diagnosis and rollback if needed

**This applies to:**
- ✅ Any `sudo reboot` or `sudo systemctl reboot` commands
- ✅ Any infrastructure changes that will be tested via reboot
- ✅ Any system updates or major configuration changes
- ✅ Testing procedures that require reboot verification

**The procedure (every time):**
```bash
# 1. Save session to docs/claude-sessions/
# 2. Commit to git:
git add .
git commit -m "Session X: [description] - Pre-reboot checkpoint"
git push

# 3. THEN execute reboot:
sudo reboot
```

**Updated:** 30 Dec 2025

---

## 📊 Key Files & Directories

**Confirmed paths in LXC 102:**
- `~/projects/` - Active projects
- `~/scripts/` - Utility scripts (auto-update, samba, ssh, nas)
- `~/docs/claude-sessions/` - Session documentation
- `~/logs/` - Log files
- `~/.github-token` - GitHub API token (gitignored)

→ See `PATHS-AND-CONFIG.md` for complete directory listing

---

## ⏱️ Token Budget

- **Weekly estimate:** ~10,000,000 tokens (40 hours/week × 250k tokens/hour)
- **Current instance:** Haiku 4.5 (faster, lower cost)
- **Rate:** ~0.8 tokens per character in responses

---

## 🔗 Other Resources

- **Proxmox Docs:** https://pve.proxmox.com/wiki/Main_Page
- **GitHub Account:** sleszgit (Sleszgit)
- **Homelab Instance:** Separate Claude Code on homelab Proxmox (LXC 102)

---

**Last Updated:** 28 Dec 2025  
**Timezone:** Europe/Warsaw  
**Date Format:** DD/MM/YYYY
