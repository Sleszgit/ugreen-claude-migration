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

## 🔧 Command Execution & Approval Workflow

### Primary Rule: Use API/SSH First, Ask Only If I Cannot

**MY DUTY:**
1. **Try to execute via API or SSH first** - Use available credentials and access
2. **Only ask the user if I cannot execute it myself** - When remote execution is blocked or impossible
3. **Never ask the user to run commands I can execute remotely** - It's wasteful and inefficient

### Execution Priority (in order):
1. **Direct execution in LXC 102** (always)
2. **SSH to UGREEN Host** (`ssh -p 22022 ugreen-host` with sudo)
3. **Proxmox API** (`curl` with `~/.proxmox-api-token`)
4. **SSH to other systems** (Homelab, NAS, etc. if credentials available)
5. **Ask the user** (LAST RESORT - only if steps 1-4 are impossible)

### Approval Workflow (if API/SSH not available):
1. **Read-only operations** → Execute directly (no approval needed)
2. **System changes** → Show command → Get approval → User executes
3. **Destructive operations** → Backup → Show command → Get approval → User executes

### Example:
**❌ WRONG:** "Run this on the Proxmox host: `sudo pve-firewall restart`"
**✅ RIGHT:** Execute it: `ssh -p 22022 ugreen-host "sudo pve-firewall restart"`

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

## 🔥 Firewall Change Safety Protocol (Added Session 101)

**CRITICAL: Before modifying ANY firewall rules affecting VLANs or container/VM access:**

### The "Ping Works But SSH Fails" Trap

**If cross-VLAN ping works but TCP services (SSH/HTTP) fail:**
- ❌ Do NOT assume the service is down
- ❌ Do NOT assume IP config is wrong (ping proves routing works)
- ✅ Check UFW `ufw route allow` rules (forwarding, not host rules)

### Key Distinction
```bash
# Opens port on HOST only - DOES NOT help containers/VMs
ufw allow 22/tcp

# Allows FORWARDED traffic through host TO containers/VMs
ufw route allow proto tcp from 192.168.40.0/24 to 10.10.10.0/24 port 22
```

### Pre-Change Checklist

Before ANY firewall changes on UGREEN host:

1. **Document current state:**
   ```bash
   sudo ufw status verbose > /tmp/ufw-backup-$(date +%Y%m%d).txt
   grep DEFAULT_FORWARD_POLICY /etc/default/ufw
   ```

2. **Test LXC102 connectivity BEFORE changes:**
   ```bash
   # From LXC102, verify we can reach the host
   ping -c 1 192.168.40.60
   ssh -p 22022 ugreen-host "echo 'SSH OK'"
   ```

3. **After changes, IMMEDIATELY test from LXC102:**
   ```bash
   ping -c 1 192.168.40.60
   ssh -p 22022 ugreen-host "echo 'SSH OK'"
   ```

4. **If SSH fails but ping works:** Problem is `ufw route` rules, NOT service/IP config

### Real Incident Reference

**Session 100-101:** VLAN10 firewall changes caused 3+ hours of LXC102 connectivity loss. Root cause: `DEFAULT_FORWARD_POLICY="DROP"` blocking forwarded TCP traffic.

→ See `INFRASTRUCTURE.md` → "Cross-VLAN Connectivity Troubleshooting" for full diagnostic protocol

**Updated:** 09 Jan 2026

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

**Last Updated:** 09 Jan 2026
**Timezone:** Europe/Warsaw
**Date Format:** DD/MM/YYYY

---

## 🏗️ Script Execution Architecture (Added Session 84)

**PRINCIPLE: Infrastructure scripts execute on their target host**

### Default Execution Locations:

**UGREEN Proxmox Host Scripts:**
- Network configuration changes
- Storage/filesystem operations
- System-level configs
- Host-level hardening

**Execution:** Run directly on UGREEN Proxmox host console (user executes):
```bash
sudo bash /nvme2tb/lxc102scripts/scriptname.sh
```

**Rationale:**
- ✅ User has direct console access to UGREEN host
- ✅ User runs scripts directly, maintaining full control
- ✅ No SSH overhead or connection dependencies
- ✅ Immediate visibility and interaction capability
- ✅ Logs stay on the host that ran them

**LXC 102 Scripts:**
- Container-specific operations
- Proxmox API calls (VMs, containers)
- Local container management

**Execution:** Direct (Claude Code runs in LXC 102, user only initiates)

**This eliminates overcomplicated patterns like:**
- ❌ nohup/screen for remote persistence
- ❌ Logging back to client for visibility
- ❌ Connection-dependent rollback procedures
- ❌ SSH tunnel dependencies

**Future Sessions:** When designing infrastructure scripts:
1. Ask: "Where does this script need to run?"
2. Create script and place in `/mnt/lxc102scripts/` (bind mount path)
3. Provide command for user to run directly on target host: `sudo bash /nvme2tb/lxc102scripts/scriptname.sh`
4. User executes directly on UGREEN console - Claude Code does NOT try to execute infrastructure scripts

---

## 💾 Session Checkpoint - The SAVE Command

**Usage:** Write `SAVE` (in capital letters) at any point to trigger a checkpoint.

### What SAVE Does

When you write `SAVE`, I will:

1. **Document the current session** - Create/update session file in `~/docs/claude-sessions/`
2. **Save all relevant files** - Include scripts, configs, documentation
3. **Commit to GitHub** - Push changes with meaningful commit message
4. **Verify and report** - Show commit hash and list of files pushed

### Session Documentation Format

Each session gets a timestamped file:
```
~/docs/claude-sessions/SESSION-95-[DESCRIPTION].md
```

File includes:
- Date and time
- Objectives completed
- Key decisions made
- Files created/modified
- Next steps / pending items
- GitHub commit hash

### Example Workflow

```
User: Create Phase 0 script
Claude: [Creates script + documentation]
User: SAVE
Claude: [Commits everything to GitHub]
Claude: ✅ Committed: abc1234 - Session 95: Phase 0 VLAN Setup
```

### Benefits

- ✅ Regular checkpoints prevent data loss
- ✅ Easy rollback if needed (git history)
- ✅ Session history preserved
- ✅ Clean documentation trail
- ✅ Team visibility into progress

**Updated:** 06 Jan 2026

