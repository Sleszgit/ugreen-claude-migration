# Claude Code Configuration - UGREEN Instance

**Device:** UGREEN DXP4800+ Proxmox (192.168.40.60)
**Container:** LXC 102 (ugreen-ai-terminal)
**User:** sleszugreen

---

## User Profile

**Skill Level:**
- NOT an IT professional - computer enthusiast learning homelab/self-hosting
- Explain technical concepts in plain language
- Don't assume knowledge of industry-standard tools

**Interface Preferences:**
- **STRONGLY PREFER web UIs** over CLI tools
- When showing CLI commands, explain what they do
- Prioritize GUI management tools when available

**Monitoring & Visibility:**
- Built-in dashboards and logs are important
- I want to see what's happening in my infrastructure

**Learning Style:**
- Explain the "why" behind recommendations
- Break down complex concepts
- Explain trade-offs in plain language

---

## Response Requirements

**ALWAYS end EVERY response with token usage:**
```
📊 Tokens: X used / 200,000 budget (Y remaining) | Weekly: Z% used | Resets: [next reset date/time]
```

**Weekly Token Limit Estimation:**
- Claude Pro published limit: 40 hours/week (conservative estimate from 40-80 range)
- Estimated tokens per hour: ~250,000 (typical for Claude Code work with Sonnet model)
- **Estimated weekly budget: 10,000,000 tokens**
- This varies based on model used and task complexity—treat as working estimate

**Command Execution Clarity:**
- **ALWAYS specify WHERE to run commands** (e.g., "ON WINDOWS DESKTOP:", "ON PROXMOX:")
- Never assume user knows which terminal/machine to use
- Be explicit about location for every command

**Security & Sensitive Information:**
- **ALWAYS tell user if it's SAFE to paste** something in the chat
- Clarify what information is safe vs sensitive
- SSH public keys (.pub files) = SAFE to share
- Private keys (no .pub extension) = NEVER share
- Passwords, tokens = Handle with explicit security guidance

**Troubleshooting Process:**
1. Ask clarification questions first
2. Analyze based on answers
3. Provide:
   - Is it solvable? (Yes/No)
   - Probability of success (X%)
   - Time estimate
   - Step-by-step solution

**Commands:**
- Use `sudo` when needed (UGREEN user has sudo access)
- Combine changes into single scripts when possible
- Test commands for correctness

**Defaults:**
- Timezone: Europe/Warsaw
- Date format: DD/MM/YYYY

---

## Task Execution Standards

### Strict Accuracy Requirements

**NEVER invent or assume:**
- Commands, file paths, configuration options, or solutions
- If uncertain, **ASK first** - never guess, improvise, or assume

**When lacking information:**
- Request specifics: OS version, error messages, logs, config files
- Consult official documentation when possible
- **Do not guess, improvise, or assume**

**Required verification:**
- **Commands**: Only provide commands that are standard for the user's confirmed environment and documented in official/reputable sources
- **File Paths/Configurations**: Only reference files or settings that are confirmed to exist (via user input or documentation)
- **Error Handling**: Always request the exact error message and context. Never assume causes or fixes
- **Critical Systems**: When in doubt, **err on the side of caution**. Ask for more information rather than risking incorrect actions

**Uncertainty Protocol:**
- If unsure, state: *"I don't have enough information to provide a safe solution. Let's verify [specific detail] first."*
- Ask for:
  - OS/software versions (e.g., `uname -a`, `lsb_release -a`, `systemctl --version`)
  - Relevant logs, config snippets, or official documentation
  - Existing file contents before suggesting modifications

**Consequences:**
- **Hallucinated solutions can cause data loss, crashes, or security risks**
- If a mistake is identified:
  1. Inform the user immediately
  2. Provide revert instructions (if applicable)
  3. Document the error in the Review section

---

### Task Execution Workflow

**1. Problem Analysis**
- Request clear description of issue/goal
- Gather:
  - Error messages/logs
  - Relevant config files (e.g., `/etc/network/interfaces`)
  - Software versions (e.g., `dpkg -l`, `systemctl --version`)
- Identify minimal scope of changes required

**2. Task Planning**
- Use `TodoWrite` tool to create interactive task list with:
  - Atomic tasks with status tracking (pending/in_progress/completed)
  - Each task includes:
    - `content`: What needs to be done (e.g., "Backup nginx.conf")
    - `activeForm`: Present continuous form (e.g., "Backing up nginx.conf")
- Example tasks:
  ```
  - [ ] Backup /etc/nginx/nginx.conf to /etc/nginx/nginx.conf.bak
  - [ ] Edit nginx.conf: Set worker_connections 1024
  - [ ] Test config with sudo nginx -t
  ```

**3. User Approval**
- **Present task plan for explicit confirmation** before execution
- **Required approval for:**
  - System changes (config edits, service restarts, installations)
  - File modifications (edits, deletions, moves)
  - Multi-step complex tasks
- **Skip approval for:**
  - Read-only operations (viewing files, checking status)
  - Simple information gathering
- **Block execution** until user confirms or requests changes

**4. Execution**
- **Sequential execution for write operations:**
  - Explain purpose in plain language before each task
  - Provide exact command/file edit
  - Mark task as `in_progress` in TodoWrite
  - Mark as `completed` immediately after finishing
- **Parallel execution allowed for:**
  - Read-only operations (checking versions, viewing files, gathering info)
  - Independent tasks with no dependencies
- **One task active at a time** - avoid batching completions

**5. Verification**
- **Simple tasks**: Inline confirmation
  - Example: *"Changed X to Y. Verified by running `Z`. Rollback: `do A`."*
- **Complex/critical tasks**: Run tests and document results
  - Example: `sudo systemctl restart nginx && curl -I localhost`
  - Document in session file if needed

**6. Review & Documentation**

| Task Type          | Review Location                              | Rollback Requirements               |
|--------------------|----------------------------------------------|--------------------------------------|
| Simple/Single-Step | Inline in chat response                      | Basic undo command                   |
| Multi-Step         | `~/docs/claude-sessions/SESSION-NAME.md`     | Detailed steps + pre-change backups  |
| Critical Systems   | **Both** chat + dedicated doc file           | Full backup + step-by-step revert    |

**Review format:**
- **Changes Made**: List of all modifications
- **Verification**: How success was confirmed
- **Rollback**: Steps to revert changes
- **Notes**: Additional context, warnings, or considerations

---

## UGREEN Infrastructure

**Access:**
- User: sleszugreen (sudo access, password required)
- Root access: `pct enter 102` from Proxmox host (emergency only)
- **CRITICAL:** All `pct` and `qm` commands REQUIRE `sudo`

**Network:**
- UGREEN Proxmox: 192.168.40.60
- Container 102 IP: 192.168.40.82
- Primary network: 192.168.40.x

**Container 102 Specs:**
- OS: Ubuntu 24.04 LTS
- CPU: 4 cores
- RAM: 4GB
- Storage: 20GB on nvme2tb (ZFS)
  - ZFS pool: nvme2tb/subvol-102-disk-0
  - Compression: LZ4 (~50% space savings)
  - Auto-TRIM enabled
- Autostart: Enabled

**UGREEN Storage Layout:**
- **System Drive:** 119GB NVMe (local-lvm) - Proxmox boot drive
- **VM/LXC Storage:** 2TB WD_BLACK SN7100 NVMe (nvme2tb pool, ZFS)
  - Used for: LXC 102 and other VM/LXC storage
  - Benefits: Fast I/O, compression, snapshots, auto-TRIM
- **Data Storage:** 4x SATA bays (for bulk storage)

**Hardware Reference:**
- Full hardware inventory: `/home/slesz/shared/projects/hardware/` (on homelab)
- GitHub: https://github.com/Sleszgit/homelab-hardware

**Proxmox Firewall Configuration:**
- **Service:** `pve-firewall.service` (restart after config changes)
- **Config file:** `/etc/pve/firewall/cluster.fw`
- **Policy:** Default DROP incoming traffic (deny-by-default security)
- **Notable:** Proxmox blocks SMB ports (445, 139) by default to prevent ransomware

---

## Samba/Windows Access

**Status:** ✅ Configured and Working

**Share Details:**
- **Share Name:** `ugreen20tb`
- **Path:** `/storage/Media` (20TB ZFS RAID1)
- **Protocol:** SMB3 (Samba 4.22.6)
- **User:** sleszugreen
- **Authentication:** Samba password (set with `smbpasswd`)

**Windows Access:**
- **Server:** `\\192.168.40.60`
- **Share:** `\\192.168.40.60\ugreen20tb`
- **Map Drive Command:**
  ```cmd
  net use Z: \\192.168.40.60\ugreen20tb /user:sleszugreen /persistent:yes
  ```
- **Access from:** 192.168.99.6 (Windows desktop)

**Firewall Rules Required:**
For Windows clients on different subnet to access Samba, add these rules to `/etc/pve/firewall/cluster.fw`:
```
# Allow SMB (Samba) from Windows desktop for NAS access
IN ACCEPT -source 192.168.99.6 -p tcp -dport 445 -log nolog
IN ACCEPT -source 192.168.99.6 -p tcp -dport 139 -log nolog
```

Then restart firewall:
```bash
sudo systemctl restart pve-firewall.service
```

**Verify Rules Applied:**
```bash
sudo iptables -L -n | grep 445
```

Should show ACCEPT rules for 192.168.99.6 before any DROP rules.

---

## Claude Code Standard

**Container Naming:**
- LXC 102 is used for Claude Code instances across all devices
- This keeps configuration consistent

**Auto-Update:**
- Script: `~/scripts/auto-update/.auto-update.sh`
- Runs on login, updates Claude Code + system packages
- Log: `~/logs/.auto-update.log`
- README: `~/scripts/auto-update/AUTO-UPDATE-README.md`

**Folder Structure:**
- `~/projects/` - Active projects (ai-projects, nas-transfer, proxmox-hardening)
- `~/scripts/` - Organized utility scripts by category
  - `auto-update/` - Auto-update system scripts
  - `samba/` - Samba/Windows access scripts
  - `ssh/` - SSH utilities
  - `nas/` - NAS file copy scripts
- `~/docs/` - Documentation files
- `~/logs/` - Log files
- `~/shared/` - Shared resources

---

## Technical Preferences

**Docker/Services:**
- Prefer Docker Compose over raw Docker
- Include restart policies and health checks
- Use environment variables (never hardcode secrets)
- Official images or well-maintained community images

**Security:**
- Never expose services without authentication
- Strong passwords, consider SSO/OAuth
- Implement proper SSL/TLS (Let's Encrypt)
- Keep services updated

**Documentation:**
- Document everything
- Track configuration changes and why
- Keep runbooks for common tasks

---

## GitHub Configuration

**User:** sleszgit
**Account:** Sleszgit
**Token:** Stored in `~/.github-token` (gitignored, not in version control)
**Scope:** repo (full access)

**Creating repos:**
```bash
GITHUB_TOKEN=$(cat ~/.github-token)
curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"repo-name","description":"Description","private":false}' \
  https://api.github.com/user/repos
```

---

## Quick Reference

**This Claude Instance Purpose:**
- UGREEN-specific tasks and service deployment
- Separate from homelab ai-terminal context
- Focused on UGREEN Proxmox infrastructure

**Other Claude Instance:**
- Homelab ai-terminal: LXC 102 on homelab Proxmox
- Has full session history and shared documentation
