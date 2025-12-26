# Task Execution Standards & Workflows

---

## Strict Accuracy Requirements

**NEVER invent or assume:**
- Commands, file paths, configuration options, or solutions
- Always verify against confirmed environment
- If uncertain: **ASK first** - never guess, improvise, or assume

**When lacking information:**
- Request specifics: OS version, error messages, logs, config files
- Consult official documentation when possible
- Don't assume causes or fixes
- Request exact error messages and context

**Required verification:**
- **Commands:** Only provide commands standard for confirmed environment and documented in official/reputable sources
- **File Paths:** Only reference files confirmed to exist (via user input or documentation)
- **Error Handling:** Always request exact error message and context. Never assume causes or fixes
- **Critical Systems:** Err on side of caution. Ask for more information rather than risking incorrect actions

**Uncertainty Protocol:**
- If unsure: "I don't have enough information to provide a safe solution. Let's verify [specific detail] first."
- Ask for:
  - OS/software versions: `uname -a`, `lsb_release -a`, `systemctl --version`
  - Relevant logs, config snippets, or official documentation
  - Existing file contents before suggesting modifications

**Consequences:**
- Hallucinated solutions can cause data loss, crashes, or security risks
- If mistake identified:
  1. Inform user immediately
  2. Provide revert instructions
  3. Document error in session

---

## Command Approval Workflow

### 1. Read-Only Operations (No Approval Needed)
Execute directly without asking:
- ✅ File viewing: `cat`, `ls`, `grep`
- ✅ Status checks: `git status`, `systemctl status`, `df -h`
- ✅ Information gathering: `uname -a`, `apt list --installed`

### 2. System Changes (Approval Required)
1. **Show** the exact command with explanation
2. **Get approval** - "Approve? [yes/no]"
3. **I execute** using Bash tool (don't ask user to run)
4. **Report results** - show what changed

Example:
```
This command will update packages:
  sudo apt upgrade -y

Changes:
  - Updates all installed packages to latest versions
  - May take 2-3 minutes
  - No breaking changes expected

Approve? [yes/no]
```

### 3. Proxmox Host Commands (Always Ask First)
1. **Show** command with explanation
2. **Ask first** - these run on Proxmox host and affect infrastructure
3. **Get approval** before executing
4. **I execute** the command
5. **Report results**

Example:
```
This will stop VM 100:
  sudo qm stop 100

Effect:
  - VM 100 will be forcefully stopped
  - Unsaved data in VM will be lost
  - Can be restarted with: sudo qm start 100

Approve? [yes/no]
```

### 4. Destructive Operations (Backup + Approval)
1. **Identify** files needing backup
2. **Show** backup command
3. **Get approval** - "Approve backup and execution?"
4. **I execute** backup: `cp /original /original.bak`
5. **I execute** destructive command
6. **Report** what was backed up and executed

Example:
```
This will modify /etc/config.conf:
  sudo sed -i 's/old/new/' /etc/config.conf

Backup:
  cp /etc/config.conf /etc/config.conf.BACKUP-20251226

Rollback:
  cp /etc/config.conf.BACKUP-20251226 /etc/config.conf

Approve? [yes/no]
```

---

## Task Execution Workflow (Multi-Step Tasks)

### Step 1: Problem Analysis
- Request clear description of issue/goal
- Gather:
  - Error messages/logs
  - Relevant config files
  - Software versions
- Identify minimal scope of changes required

### Step 2: Task Planning
- Use `TodoWrite` tool to create interactive task list
- Each task includes:
  - `content`: What needs to be done (e.g., "Backup nginx.conf")
  - `activeForm`: Present continuous form (e.g., "Backing up nginx.conf")
  - `status`: pending/in_progress/completed
- Example:
  ```
  - Backup /etc/nginx/nginx.conf to /etc/nginx/nginx.conf.bak
  - Edit nginx.conf: Set worker_connections 1024
  - Test config with sudo nginx -t
  - Restart nginx service
  ```

### Step 3: User Approval
- **Present task plan** for explicit confirmation before execution
- **Approval required for:**
  - System changes (config edits, service restarts)
  - File modifications (edits, deletions, moves)
  - Multi-step complex tasks
- **Skip approval for:**
  - Read-only operations (viewing files, checking status)
  - Simple information gathering
- **Block execution** until user confirms or requests changes

### Step 4: Sequential Execution
For each task:
1. **Explain purpose** in plain language
2. **Show exact command/file edit** for approval (if needed)
3. **Get explicit approval** (except direct LXC 102 commands)
4. **Execute myself** using Bash/Edit tools
5. **Mark task as `in_progress`** in TodoWrite
6. **Mark as `completed`** immediately after finishing

### Step 5: Verification
- **Simple tasks:** Inline confirmation
  - "Changed X to Y. Verified by running `Z`. Rollback: `do A`."
- **Complex/critical tasks:** Run tests and document results
  - Example: `sudo systemctl restart nginx && curl -I localhost`
  - Document in session file if needed

### Step 6: Review & Documentation

| Task Type | Review Location | Rollback Requirements |
|-----------|-----------------|----------------------|
| Simple/Single-Step | Inline in chat response | Basic undo command |
| Multi-Step | `~/docs/claude-sessions/SESSION-NAME.md` | Detailed steps + pre-change backups |
| Critical Systems | Both chat + dedicated doc file | Full backup + step-by-step revert |

---

## Direct Execution in LXC 102

**Execute directly without asking (routine operations):**
- ✅ Package management: `apt update`, `apt upgrade`, `apt install`
- ✅ npm operations: `npm update -g`, `npm install -g`
- ✅ File operations: `ls`, `cp`, `mkdir`, `rm`, `cat`, `grep`
- ✅ Claude Code: `claude --version`, `claude` CLI commands
- ✅ Read-only checks: `git status`, `ls -la`, `pwd`
- ✅ System info: `uname -a`, `df -h`, `free -m`

**Commands REQUIRING approval first:**
- ❌ Proxmox management: `pct`, `qm`, `pvesh` (HOST only - ask first)
- ❌ Critical config changes: Editing `/etc/` files, systemd services
- ❌ Destructive operations: `rm -rf`, clearing logs, deleting data
- ❌ Multi-step operations with potential rollback needs

---

## Security & Sensitive Information

**ALWAYS tell user if it's SAFE to paste something:**
- Clarify what information is safe vs sensitive
- ✅ **SAFE to share:** SSH public keys (.pub files), documentation, code snippets
- ❌ **NEVER share:** Private keys, passwords, API tokens, `~/.github-token`, `~/.proxmox-*-token`
- ❌ **Handle carefully:** Authentication methods, system configuration with secrets

---

## Common Troubleshooting Process

**Standard approach for errors:**
1. Ask clarification questions first
2. Analyze based on answers
3. Provide:
   - Is it solvable? (Yes/No)
   - Probability of success (X%)
   - Step-by-step solution

**Before proposing fix:**
- Always read relevant files first
- Check logs if available
- Understand existing code/configuration
- Never modify code you haven't read

---

## Destructive Command Workflow (Detailed)

**Stop and ask if command might:**
- Delete operations: `rm`, `rm -rf`, `pct destroy`, `qm destroy`
- Modify system config files
- Restart/stop services: `systemctl restart`, `pct destroy`, `qm destroy`
- Overwrite existing files
- Clear logs or data

**Required workflow:**
1. Show exact command
2. Explain what it does
3. **Identify files that need backup** (which files/directories)
4. **Ask for approval** - "Approve backup and execution?"
5. **Execute backup myself** - `cp /original /original.bak`
6. **Execute destructive command myself** - (I run this, don't ask you to run it)
7. **Report results** - show what was backed up and executed

**Key principle:** You approve the action, I execute everything (backups + command).

---

## Automated Checks (No Need to Ask)

✅ **Already verified and documented:**
- Command location: Use "System Identification" guide (hostname in prompt)
- Command syntax: Reference `PROXMOX-COMMANDS.md`
- Directory paths: All verified and listed in `PATHS-AND-CONFIG.md`
- Sudo permissions: Documented in `PATHS-AND-CONFIG.md`
- Location specification: Always clarify ON PROXMOX HOST vs IN LXC 102

---

## When to Use TodoWrite

**Create todo list when:**
- 3+ distinct steps or actions needed
- Non-trivial or complex tasks
- Multi-file changes
- Unclear requirements (after exploration)
- User preferences affect implementation

**Update task status:**
- Mark `in_progress` BEFORE starting work
- Mark `completed` IMMEDIATELY after finishing (don't batch)
- Keep exactly ONE task active at a time
- Remove tasks no longer relevant

---

## Error Handling & Recovery

**If something goes wrong:**
1. **Stop immediately** - don't continue
2. **Inform user** - describe what happened
3. **Analyze** - what caused the error?
4. **Provide options:**
   - Rollback instructions (if available)
   - Alternative approaches
   - Next steps

**Document mistakes:**
- Write to session file with:
  - What went wrong
  - Why it happened
  - How to prevent next time
  - What was rolled back (if applicable)

---

## See Also

- `CLAUDE.md` - Main configuration (hub)
- `PATHS-AND-CONFIG.md` - Directories and command locations
- `PROXMOX-COMMANDS.md` - Command reference for Proxmox host
