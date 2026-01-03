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

## 🌐 NETWORK TOPOLOGY (Updated 03 Jan 2026)

**I RUN HERE:** LXC 102 @ 192.168.40.82 (on UGREEN Proxmox 192.168.40.60)

| Device | IP | How to Connect | Status |
|--------|-----|----------------|--------|
| **UGREEN Host** | 192.168.40.60 | `ssh ugreen-host` (port 22022) | ✅ |
| **Homelab** | 192.168.40.40 | `ssh homelab` | ✅ |
| **920 NAS** | 192.168.40.20 | `ssh backup-user@192.168.40.20` | ✅ |
| **Pi400** | 192.168.40.50 | Pi-Hole DNS | ✅ |
| **Pi3B** | 192.168.40.30 | Technitium DNS | ✅ |
| **UGREEN API** | 192.168.40.60:8006 | curl with `~/.proxmox-api-token` | ✅ |

**⚠️ NEVER CONFUSE:**
- **192.168.40.60** = UGREEN (where I run)
- **192.168.40.40** = HOMELAB (main Proxmox server)

**Full topology:** See `~/.claude/ENVIRONMENT.yaml`
**Status check:** `~/scripts/infrastructure/check-env-status.sh`

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

## 🤖 Gemini Pro Helper Integration

**Role:** Gemini CLI acts as your Reasoning Sub-agent for heavy analytical tasks.

### Technical Execution (The '!' Protocol)
**Default Command:** `! gemini -p "[Instruction]" [Files]`
**Piping Context:** `! echo "[Code]" | gemini -p "Analyze this snippet"`

### Delegation Workflows

**Complex Logic Audit** (function >50 lines, high cyclomatic complexity):
```bash
! gemini -p "Perform a rigorous logic audit. Look for edge cases, race conditions, and off-by-one errors." <filename>
```

**Security Review** (auth, tokens, API keys, sensitive data):
```bash
! gemini -p "Act as a security researcher. Identify potential vulnerabilities in this implementation." <filename>
```

**Code Review (Second Opinion)** (before PR/major change):
```bash
! gemini -p "Compare this new implementation with standard best practices. List 3 potential improvements." <filename>
```

### Shared Context Sync
1. **Rule Sync:** `! [ -L GEMINI.md ] || ln -s CLAUDE.md GEMINI.md`
2. **Shared Memory:** Use `./.ai_context/` directory for state
3. **State Handover:** `! echo "Goal: [Task]" > .ai_context/current_mission.tmp`

### Decision Loop
1. Formulate plan
2. If complex → consult Gemini for sanity check
3. Read Gemini output into context
4. Refine plan based on feedback
5. Execute final code

**When to use Gemini:**
- ✅ Complex logic (>50 lines)
- ✅ Security-critical code
- ✅ Before finalizing major changes
- ✅ When multiple approaches exist
- ❌ Simple tasks (<10 lines, obvious logic)
- ❌ When you've given explicit instructions (follow directly)

---

## 🔗 Other Resources

- **Proxmox Docs:** https://pve.proxmox.com/wiki/Main_Page
- **GitHub Account:** sleszgit (Sleszgit)
- **Homelab Instance:** Separate Claude Code on homelab Proxmox (LXC 102)

---

**Last Updated:** 03 Jan 2026  
**Timezone:** Europe/Warsaw  
**Date Format:** DD/MM/YYYY
