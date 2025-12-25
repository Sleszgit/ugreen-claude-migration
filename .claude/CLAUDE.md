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
- **DEFAULT LOCATION: Always assume we are in LXC 102 (ugreen-ai-terminal) on UGREEN UNLESS user explicitly says otherwise**
- Only use location prefixes (e.g., "ON PROXMOX HOST:", "ON WINDOWS:") when NOT in LXC 102
- When user mentions a different location, acknowledge it clearly and use that location for all subsequent commands
- Be explicit about location changes to avoid confusion

**SSH & API Access (Important - 25 Dec 2025):**
- ⚠️ **SSH from container → Proxmox host is NOT configured**
- ⚠️ **SSH from homelab → UGREEN is NOT configured**
- Always use Proxmox API instead with tokens: `~/.proxmox-api-token` (UGREEN), `~/.proxmox-homelab-token` (homelab)
- For file transfers between systems when SSH not available: Use heredoc/cat method to create files directly, not SCP

---

### Proxmox API Access Setup (Container → Host) - CRITICAL FIX

**⚠️ LESSON LEARNED (25 Dec 2025):**
- **DON'T use `/etc/pve/firewall/cluster.fw` for container↔host API access**
- Proxmox firewall config creates RETURN rules in custom chains, not direct ACCEPT
- Result: Configuration looks correct but traffic is still blocked
- **Solution: Use direct iptables rules instead**

**Correct Setup (Permanent):**

**ON PROXMOX HOST, run ONCE:**
```bash
sudo iptables -I INPUT 1 -s 192.168.40.82 -p tcp --dport 8006 -j ACCEPT
```

This creates:
```
ACCEPT     tcp  --  192.168.40.82        0.0.0.0/0            tcp dpt:8006
```

**Make Persistent:**
```bash
# Option 1: Add to /etc/pve/firewall/cluster.fw (BELOW other rules for override):
echo "IN ACCEPT -source 192.168.40.82 -p tcp -dport 8006" >> /etc/pve/firewall/cluster.fw
sudo systemctl restart pve-firewall.service

# Option 2: Save iptables directly (if available):
sudo iptables-save > /etc/iptables/rules.v4
```

**Verify Setup:**
```bash
# From container:
bash /mnt/lxc102scripts/test-api-from-container.sh

# Should show: "✅ API call succeeded!" and return Proxmox version
```

**Status (25 Dec 2025):** ✅ Properly configured and tested working

---

### Script Placement - CRITICAL (Apply Rigorously)

**ALL utility scripts must be placed in the LXC 102 bind mount to be accessible from both container AND Proxmox host:**

**Two paths point to the SAME directory:**
```
FROM CONTAINER (LXC 102):        /mnt/lxc102scripts/
FROM PROXMOX HOST:               /nvme2tb/lxc102scripts/
MOUNT CONFIGURATION:             mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts
```

**Placement Rule (RIGID - Do Not Deviate):**

1. **When creating scripts in LXC 102 container:**
   - Write to: `/mnt/lxc102scripts/scriptname.sh`
   - Make executable: `chmod +x /mnt/lxc102scripts/scriptname.sh`
   - User can immediately run on Proxmox host at: `/nvme2tb/lxc102scripts/scriptname.sh`

2. **When referencing from Proxmox host:**
   - Full path: `/nvme2tb/lxc102scripts/scriptname.sh`
   - Execute: `sudo bash /nvme2tb/lxc102scripts/scriptname.sh`

3. **When referencing from container:**
   - Full path: `/mnt/lxc102scripts/scriptname.sh`
   - Execute: `bash /mnt/lxc102scripts/scriptname.sh`

**DO NOT create scripts:**
- ❌ In `~/scripts/` for Proxmox host execution
- ❌ In `/root/` on Proxmox host (unless they will NEVER be updated)
- ❌ In `/tmp/` for persistent use
- ❌ Anywhere outside the bind mount if they need Proxmox host access

**Script Organization Within Bind Mount:**
```
/mnt/lxc102scripts/
├── enable-proxmox-api-access.sh     ← Firewall setup (ALREADY EXISTS)
├── vm100ugreen/                     ← VM 100 UGREEN hardening
│   ├── hardening/
│   │   ├── 00-pre-hardening-checks.sh
│   │   ├── 01-ssh-hardening.sh
│   │   └── ... (Phase A/B/C scripts)
│   └── general/
├── vm100homelab/                    ← Separate namespace for homelab VM 100
├── transfer-scripts/                ← File transfer automation (future)
└── utilities/                       ← Shared utilities
```

**Example Usage (Correct):**
```bash
# Creating script in container:
cat > /mnt/lxc102scripts/my-script.sh << 'EOF'
#!/bin/bash
echo "test"
EOF
chmod +x /mnt/lxc102scripts/my-script.sh

# Running from Proxmox host:
sudo bash /nvme2tb/lxc102scripts/my-script.sh

# Running from container:
bash /mnt/lxc102scripts/my-script.sh
```

**⚠️ DO NOT:**
```bash
# WRONG - Creates file in container only:
cat > ~/my-script.sh

# WRONG - Tries to reference non-existent path:
/nvme2tb/lxc102scripts/my-script.sh (when created in ~/)

# WRONG - Tries to use container path on Proxmox host:
sudo bash /mnt/lxc102scripts/my-script.sh (from Proxmox, should use /nvme2tb/)
```

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

**Command Approval & Execution:**
- For LXC 102 commands: Execute directly without asking (routine operations)
- For system changes: Show command → get approval → execute yourself (don't ask user to run)
- For Proxmox host commands: Always ask first

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
  - Provide exact command/file edit for approval
  - **Get explicit approval before executing** (except for direct LXC 102 commands)
  - **Execute the command yourself** using Bash tool - do not ask user to run it
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

## Command Reference & Execution Guide

### System Identification (Critical for Command Location)

**Always identify where you are by the shell prompt hostname:**

```
ON PROXMOX HOST (Proxmox management):
  Prompt: sleszugreen@ugreen:~$
  - Root user: root@ugreen:~#
  - Use: pveversion, pct, qm, pvesh commands
  - All container/VM management commands run here

IN LXC 102 CONTAINER (ugreen-ai-terminal):
  Prompt: sleszugreen@ugreen-ai-terminal:~$
  - Use: apt, npm, Claude Code, application-level commands
  - Proxmox management commands NOT available here
```

**⚠️ CRITICAL:** Before providing ANY command, verify the prompt hostname matches the required location.

---

### Proxmox API Access (Read-Only) - ✅ WORKING

**⚠️ PREREQUISITE:** Firewall rule must be configured first (see "Proxmox API Access Setup" section above)

**Token Setup:** ✅ Configured (25 Dec 2025)

Two read-only API tokens are stored securely:

#### Token 1: Cluster-Wide Reader (claude-reader@pam)
```
Token File:        ~/.proxmox-api-token (gitignored, mode 600)
Token ID:          claude-reader@pam!claude-token
User:              claude-reader@pam
Role:              PVEAuditor (read-only cluster access)
Permissions:       Query all containers, VMs, nodes, status, logs
Restrictions:      NO write/modify/delete operations
```

#### Token 2: VM 100 Reader (vm100-reader@pam)
```
Token File:        ~/.proxmox-vm100-token (gitignored, mode 600)
Token ID:          vm100-reader@pam!vm100-token
User:              vm100-reader@pam
Role:              PVEAuditor (read-only cluster access)
Permissions:       Query VM 100 status, logs, resources
Restrictions:      NO write/modify/delete operations
```

**Usage Examples (from container):**
```bash
# Query cluster status
PROXMOX_TOKEN=$(cat ~/.proxmox-api-token)
curl -k -H "Authorization: PVEAPIToken=claude-reader@pam!claude-token=$PROXMOX_TOKEN" \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/status

# Query VM 100 status
VM100_TOKEN=$(cat ~/.proxmox-vm100-token)
curl -k -H "Authorization: PVEAPIToken=vm100-reader@pam!vm100-token=$VM100_TOKEN" \
  https://192.168.40.60:8006/api2/json/nodes/ugreen/qemu/100/status/current
```

**Why This Approach:**
- ✅ Zero risk of accidental modifications (read-only enforced at Proxmox level)
- ✅ Tokens can be revoked instantly: `sudo pveum user token delete <user> <tokenid>`
- ✅ All API calls are logged by Proxmox
- ✅ Better than SSH: Safer, more auditable, no shell access
- ✅ Separate tokens per purpose (cluster vs specific VM)
- ✅ Works from container to host with proper firewall setup

---

### Confirmed Directory Paths (LXC 102)

These directories are confirmed to exist and can be referenced without verification:

**Project & Work Directories:**
- `~/projects/` - Active projects (ai-projects, nas-transfer, proxmox-hardening)
- `~/projects/ai-projects/` - AI-related projects
- `~/projects/nas-transfer/` - NAS transfer automation
- `~/projects/proxmox-hardening/` - Proxmox security hardening

**Script Directories:**
- `~/scripts/` - Root directory for utility scripts
- `~/scripts/auto-update/` - Auto-update system scripts
- `~/scripts/auto-update/.auto-update.sh` - Main auto-update script
- `~/scripts/samba/` - Samba/Windows access scripts
- `~/scripts/ssh/` - SSH utilities
- `~/scripts/nas/` - NAS file copy scripts

**Documentation Directories:**
- `~/docs/` - Documentation files
- `~/docs/claude-sessions/` - Session notes and documentation
- `~/docs/sessions/` - Alternative session location
- `~/docs/hardware/` - Hardware documentation

**Logging & Support:**
- `~/logs/` - Log files
- `~/logs/.auto-update.log` - Auto-update script log
- `~/.claude/CLAUDE.md` - This configuration file

**Important Configuration Files:**
- `~/.github-token` - GitHub API token (gitignored)
- `~/.bashrc` - Shell configuration
- `~/.ssh/` - SSH keys and config directory

**Shared Resources:**
- `~/shared/` - Shared resources (when accessible)

**LXC 102 Bind Mount (Proxmox Host ↔ Container):**
- **Proxmox Host:** `/nvme2tb/lxc102scripts/` - Source directory on Proxmox host
- **Container:** `/mnt/lxc102scripts/` - Bind mount point in LXC 102
- **Purpose:** Shared access for scripts and files between Proxmox host and container
- **Mount Config:** `mp1: /nvme2tb/lxc102scripts,mp=/mnt/lxc102scripts`

---

### Command Location Matrix

| Command Category | Location | Example | Notes |
|------------------|----------|---------|-------|
| **Proxmox Management** | HOST ONLY | `sudo pveversion` | pct, qm, pvesh, pveversion |
| **Container Management** | HOST ONLY | `sudo pct exec 102 -- apt update` | Managing LXC 102 from host |
| **System Packages** | IN CONTAINER | `apt update`, `apt upgrade` | When logged into ugreen-ai-terminal |
| **Claude Code** | IN CONTAINER | `claude --version` | Updates via `npm update -g` |
| **File Operations** | IN CONTAINER | `ls ~/docs/`, `cp file1 file2` | Local file work |
| **Sudo Passwordless** | IN CONTAINER | `sudo -n npm update -g @anthropic-ai/claude-code` | Configured via sudoers |

---

### Direct Execution in LXC 102

**Execute these commands directly without asking (routine operations in your container):**
- ✅ Package management: `apt update`, `apt upgrade`, `apt install`
- ✅ npm operations: `npm update -g`, `npm install -g`
- ✅ File operations: `ls`, `cp`, `mkdir`, `rm`, `cat`, `grep`
- ✅ Claude Code: `claude --version`, `claude` CLI commands
- ✅ Read-only checks: `git status`, `ls -la`, `pwd`, etc.
- ✅ System info: `uname -a`, `df -h`, `free -m`

**Commands that REQUIRE approval first:**
- ❌ Proxmox management: `pct`, `qm`, `pvesh` (HOST only - ask first)
- ❌ Critical config changes: Editing `/etc/` files, systemd services
- ❌ Destructive operations: `rm -rf`, clearing logs, deleting data
- ❌ Multi-step operations with potential rollback needs

**Workflow for approval-required commands:**
1. Show command with explanation
2. Get your approval
3. Execute it myself with Bash tool (don't ask you to run it)
4. Report results

---

### Scripts in /nvme2tb/lxc102scripts (Proxmox Host)

**Important:** Scripts stored in the bind mount directory (`/nvme2tb/lxc102scripts/`) that perform privileged operations **MUST be run with `sudo`** on the Proxmox host.

**Examples of operations requiring sudo:**
- ✅ NFS mounting: `sudo mount -t nfs`
- ✅ Writing to `/storage/Media/` (ZFS dataset)
- ✅ Creating logs in `/root/nas-transfer-logs/`
- ✅ rsync to protected directories

**Correct usage:**
```bash
# On Proxmox host
sudo bash /nvme2tb/lxc102scripts/copy-volume3-archive.sh
```

**Important note:** When Claude Code creates scripts in the container's `/mnt/lxc102scripts/` bind mount, those scripts are automatically accessible on the Proxmox host at `/nvme2tb/lxc102scripts/` but will require `sudo` to execute if they perform privileged operations.

---

### Proxmox Command Syntax Reference (Proxmox Host Only)

#### pct - Container Management

**pct exec** - Execute command inside container
```bash
pct exec <vmid> [<extra-args>] [OPTIONS]

Examples:
sudo pct exec 102 -- apt update
sudo pct exec 102 -- npm update -g @anthropic-ai/claude-code
sudo pct exec 102 -- bash -c "echo 'test' > /tmp/file.txt"

Options:
  --keep-env <boolean>  Keep environment variables
```

**pct enter** - Interactive shell in container
```bash
pct enter <vmid> [OPTIONS]

Example:
sudo pct enter 102

Options:
  --keep-env <boolean>  Keep environment variables
```

**pct push** - Copy file TO container
```bash
pct push <vmid> <file> <destination> [OPTIONS]

Example:
sudo pct push 102 /local/path/file.txt /container/path/file.txt

Options:
  --user <string>       File owner user (default: root)
  --group <string>      File owner group (default: root)
  --perms <string>      File permissions (default: 0644)
```

**pct pull** - Copy file FROM container
```bash
pct pull <vmid> <path> <destination> [OPTIONS]

Example:
sudo pct pull 102 /var/log/syslog /local/path/syslog

Options:
  --user <string>       File owner user
  --group <string>      File owner group
  --perms <string>      File permissions
```

**pct status** - Show container state
```bash
pct status <vmid> [OPTIONS]

Example:
sudo pct status 102
sudo pct status 102 --verbose

Options:
  --verbose             Show detailed status
```

**pct list** - List all containers
```bash
pct list

Shows: VMID, NAME, STATUS, NODE, CPU, MEMORY, DISK
```

**pct create** - Create new container
```bash
pct create <vmid> <ostemplate> [OPTIONS]

Example:
sudo pct create 103 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst -hostname newcontainer -memory 2048

Key OPTIONS:
  -hostname <string>    Container hostname
  -memory <integer>     Memory in MB
  -swap <integer>       Swap in MB
  -storage <string>     Storage pool
  -net0 <string>        Network configuration
  -mp0 <string>         Mount point
  -rootfs <string>      Root filesystem size
```

**pct set** - Modify container configuration
```bash
pct set <vmid> [OPTIONS]

Examples:
sudo pct set 102 -memory 4096
sudo pct set 102 -onboot 1
sudo pct set 102 -hostname newhostname
sudo pct set 102 -mp0 /mnt/bindmount,mp=/mnt/shared

Key OPTIONS:
  -memory <integer>     Memory in MB
  -swap <integer>       Swap in MB
  -onboot <boolean>     Start on boot (0/1)
  -hostname <string>    Container hostname
  -net0 <string>        Network config
  -mp<N> <string>       Mount point
```

**pct destroy** - Delete container
```bash
pct destroy <vmid> [OPTIONS]

Example:
sudo pct destroy 102 --purge

Options:
  --force               Force destruction
  --purge               Remove config and data
  --destroy-unreferenced-disks  Delete unused volumes
```

**pct clone** - Copy container
```bash
pct clone <vmid> <newid> [OPTIONS]

Example:
sudo pct clone 102 103 -hostname cloned-container

Options:
  -hostname <string>    New container hostname
  -storage <string>     Target storage pool
  -full <boolean>       Full clone (1) or linked (0)
```

**pct migrate** - Move container to different node
```bash
pct migrate <vmid> <target> [OPTIONS]

Example:
sudo pct migrate 102 proxmoxnode2

Options:
  --online              Live migration (if supported)
  --restart             Restart if live migration fails
```

---

#### qm - Virtual Machine Management

**qm start** - Start VM
```bash
qm start <vmid> [OPTIONS]

Example:
sudo qm start 100
```

**qm stop** - Forcefully stop VM
```bash
qm stop <vmid> [OPTIONS]

Example:
sudo qm stop 100
```

**qm shutdown** - Graceful VM shutdown
```bash
qm shutdown <vmid> [OPTIONS]

Example:
sudo qm shutdown 100 --timeout 60

Options:
  --timeout <integer>   Seconds to wait (default: 60)
  --force               Force shutdown
```

**qm status** - Show VM status
```bash
qm status <vmid>

Example:
sudo qm status 100

Output: running, stopped, paused, etc.
```

**qm list** - List all VMs
```bash
qm list [OPTIONS]

Shows: VMID, NAME, STATUS, MEM(MB), BOOTDISK(GB), PID
```

**qm reboot** - Reboot VM
```bash
qm reboot <vmid> [OPTIONS]

Example:
sudo qm reboot 100

Options:
  --timeout <integer>   Seconds to wait (default: 60)
```

**qm suspend** - Pause VM (preserve state)
```bash
qm suspend <vmid> [OPTIONS]

Example:
sudo qm suspend 100
```

**qm resume** - Resume paused VM
```bash
qm resume <vmid> [OPTIONS]

Example:
sudo qm resume 100
```

**qm reset** - Hard reset VM
```bash
qm reset <vmid> [OPTIONS]

Example:
sudo qm reset 100
```

**qm create** - Create new VM
```bash
qm create <vmid> [OPTIONS]

Example:
sudo qm create 101 -name myvm -memory 2048 -sockets 2 -cores 2 -storage local

Key OPTIONS:
  -name <string>        VM name
  -memory <integer>     Memory in MB
  -sockets <integer>    CPU sockets
  -cores <integer>      CPU cores per socket
  -net0 <string>        Network config
  -scsi0 <string>       SCSI disk
  -ide2 <string>        IDE device (CD-ROM)
```

**qm destroy** - Delete VM
```bash
qm destroy <vmid> [OPTIONS]

Example:
sudo qm destroy 100 --purge

Options:
  --purge               Remove all related data
  --force               Force destruction
```

---

#### pvesh - Proxmox VE API Shell

**pvesh get** - Query API (GET request)
```bash
sudo pvesh get <api_path> [OPTIONS] [FORMAT_OPTIONS]

Examples:
sudo pvesh get /nodes                          # List all nodes
sudo pvesh get /nodes/ugreen                   # Get node info
sudo pvesh get /nodes/ugreen/lxc               # List containers on node
sudo pvesh get /nodes/ugreen/qemu              # List VMs on node
sudo pvesh get /cluster/status                 # Cluster status
```

**pvesh set** - Modify via API (PUT request)
```bash
sudo pvesh set <api_path> [OPTIONS] [FORMAT_OPTIONS]

Examples:
sudo pvesh set /cluster/options -console html5
sudo pvesh set /nodes/ugreen/config -maxlen 16384
```

**pvesh create** - Create resource via API (POST request)
```bash
sudo pvesh create <api_path> [OPTIONS]

Example:
sudo pvesh create /nodes/ugreen/lxc -vmid 105 -hostname container105 -storage local --password "pass"
```

**pvesh delete** - Delete resource (DELETE request)
```bash
sudo pvesh delete <api_path> [OPTIONS]

Example:
sudo pvesh delete /nodes/ugreen/lxc/105
```

**pvesh ls** - List child objects
```bash
sudo pvesh ls <api_path> [OPTIONS]

Example:
sudo pvesh ls /nodes/ugreen
```

**pvesh usage** - Show API endpoint documentation
```bash
sudo pvesh usage <api_path> [OPTIONS]

Example:
sudo pvesh usage /nodes/ugreen/lxc -v    # Verbose endpoint info

Options:
  -v                    Verbose (show all parameters)
```

**Common Format Options:**
```bash
--output-format json              # JSON output
--output-format json-pretty       # Pretty-printed JSON
--output-format text              # Text output
--output-format yaml              # YAML output
--human-readable                  # Format for human readability
--quiet                           # Suppress output
```

---

#### pveum - Proxmox User and Permission Management

**pveum user add** - Create new user
```bash
sudo pveum user add <userid> [OPTIONS]

Example:
sudo pveum user add claude-reader@pam

Options:
  --email <string>      User email
  --enable <boolean>    Enable/disable user (1/0)
  --expire <integer>    Account expiration (unix timestamp)
  --firstname <string>  First name
  --lastname <string>   Last name
  --password <string>   User password
```

**pveum user token add** - Create API token for user (Read-Only Access Setup ✅)
```bash
sudo pveum user token add <userid> <tokenid> [OPTIONS] [FORMAT_OPTIONS]

Example:
sudo pveum user token add claude-reader@pam claude-token --expire 0

Options:
  --expire <integer>    Token expiration (0 = never)
  --privsep <boolean>   Privilege separation (1/0)

Output includes:
  - full-tokenid: <userid>!<tokenid>
  - token: <long-random-string> (SAVE THIS!)

IMPORTANT: Save the token value immediately - it's only shown once!
```

**pveum user token list** - List user tokens
```bash
sudo pveum user token list <userid> [FORMAT_OPTIONS]

Example:
sudo pveum user token list claude-reader@pam

Shows all active tokens for the user
```

**pveum user token delete** - Revoke token
```bash
sudo pveum user token delete <userid> <tokenid> [FORMAT_OPTIONS]

Example:
sudo pveum user token delete claude-reader@pam claude-token

Immediately revokes token access
```

**pveum acl modify** - Assign roles/permissions to users
```bash
sudo pveum acl modify <path> --roles <string> [OPTIONS]

Examples:
sudo pveum acl modify / -user claude-reader@pam -role PVEAuditor    # Read-only access to entire cluster
sudo pveum acl modify /nodes/ugreen -user alice@pam -role PVEAdmin   # Admin on specific node

Available Roles:
  PVEAuditor              Read-only access (perfect for monitoring/queries)
  PVEAdmin                Full administrative access
  PVEVMAdmin              VM/Container management only
  PVEPoolAdmin            Pool management
  PVEDatastoreAdmin       Storage management
  PVEBackupOperator       Backup operations only
```

**pveum user list** - List all users
```bash
sudo pveum user list [OPTIONS] [FORMAT_OPTIONS]

Example:
sudo pveum user list

Shows all users and their authentication realms
```

---

#### System Commands

**pveversion** - Check Proxmox version
```bash
pveversion

Output: pve-manager/9.1.2/... (running kernel: 6.17.4-1-pve)
```

**Firewall Management**
```bash
# Check firewall status
sudo systemctl status pve-firewall.service

# View firewall rules
sudo iptables -L -n

# Restart firewall (after config changes)
sudo systemctl restart pve-firewall.service
```

---

**Documentation Sources:**
- [pct(1) Manual](https://pve.proxmox.com/pve-docs/pct.1.html)
- [qm(1) Manual](https://pve.proxmox.com/pve-docs/qm.1.html)
- [pvesh(1) Manual](https://pve.proxmox.com/pve-docs/pvesh.1.html)
- [pveum(1) Manual](https://pve.proxmox.com/pve-docs/pveum.1.html)
- [Proxmox VE API Documentation](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [Proxmox User Management Guide](https://pve.proxmox.com/wiki/User_Management)

---

### Environment Variables & Sudo

**Sudo strips environment variables by default for security.** If a command needs environment variables:

**Problem:**
```bash
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
# Error: sudo: sorry, you are not allowed to set the following environment variables: DEBIAN_FRONTEND
```

**Solution:**
- Either allow in sudoers: `Defaults!/usr/bin/apt env_keep += "DEBIAN_FRONTEND"`
- Or use passwordless commands only (already configured for your user)

---

### Sudoers Configuration (sleszugreen User)

**General sudo access:**
- User has full sudo access: `(ALL : ALL) ALL`
- Requires password for most commands

**Passwordless (NOPASSWD) commands:**
```bash
sudo npm update -g @anthropic-ai/claude-code        # Update Claude Code
sudo apt update                                     # Update package list
sudo apt upgrade -y                                 # Upgrade packages
sudo apt autoremove -y                              # Remove unused packages
```

**Environment variable handling:**
- `DEBIAN_FRONTEND=noninteractive` is allowed for apt commands
- Use: `sudo apt upgrade -y` (DEBIAN_FRONTEND preserved automatically)

**Proxmox host commands (when on Proxmox host):**
- Require password: `sudo pct`, `sudo qm`, `sudo pvesh`
- These are not configured for passwordless in this container

**Summary for command planning:**
- ✅ Package updates (apt) = passwordless
- ✅ Claude Code updates (npm) = passwordless
- ✅ File operations = based on permissions
- ⚠️ Proxmox commands = require password
- ⚠️ System config changes = require password
- ⚠️ Service management (systemctl) = require password

---

### Destructive Command Workflow

**Stop and ask user for explicit consent if command might have:**
- Delete operations (rm, rm -rf)
- Modify system config files
- Restart/stop services (systemctl restart, pct destroy, qm destroy)
- Overwrite existing files

**Workflow for destructive commands in LXC 102:**
1. Show the exact command with explanation of what it does
2. **Identify files that need backup** - specify which files/directories
3. **Ask for approval** - "Approve backup and execution?"
4. **Execute backup myself** - `cp /original /original.bak` (I run this)
5. **Execute destructive command myself** - (I run this, don't ask you to run it)
6. **Report results** - show what was backed up and executed

**Example workflow:**
```
This command will modify /etc/config.conf.

Files to backup:
  - /etc/config.conf → /etc/config.conf.BACKUP-YYYY-MM-DD

After backup, will execute:
  sudo sed -i 's/old/new/' /etc/config.conf

Rollback available: sudo cp /etc/config.conf.BACKUP-YYYY-MM-DD /etc/config.conf

Approve? [yes/no]
```

**Key principle:** You approve the action, I execute everything (backups + command).

---

### Automated checks (no need to ask):
- ✅ Command location: Always identify using "System Identification" guide (hostname in prompt)
- ✅ Command syntax: Reference "Proxmox Command Syntax Reference" section
- ✅ Directory paths: All verified and listed in "Confirmed Directory Paths"
- ✅ Sudo permissions: Documented in "Sudoers Configuration"
- ✅ Remember to always specify location (ON PROXMOX HOST / ON LXC 102 CONTAINER)

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

## VM Creation Best Practices (Lessons Learned - 25 Dec 2025)

### ⚠️ CRITICAL: UEFI/IDE CDROM Unmount Bug (Known Issue)

**DO NOT use Ubuntu ISO with IDE2 CDROM without workaround:**

```
Problem: UEFI (OVMF) firmware cannot cleanly release IDE device during reboot
Configuration that triggers the bug:
  - bios: ovmf
  - machine: q35
  - ide2: [ISO],media=cdrom
  - boot: order=scsi0;ide2;net0

Result: Ubuntu installer completes → tries umount /cdrom → FAILS → boot loop
Root Cause: QEMU/OVMF limitation (unfixable in hardware, KNOWN BUG)
```

**If using ISO approach, workaround is required:**
1. Let Ubuntu installer complete normally
2. When unmount fails → **IMMEDIATELY STOP** (don't wait for reboot)
3. Use Proxmox web UI: VM config → Hardware → Delete IDE2 device
4. OR set IDE2 to "none": `sudo qm set 100 -ide2 none`
5. Force reboot from console: `sudo reboot -f`
6. VM boots successfully from disk

---

### ✅ Cloud-Init on Proxmox: PROVEN RELIABLE (25 Dec 2025 - VM 100 Verified)

**Cloud-init works perfectly on UGREEN Proxmox despite DataSourceNone:**

**VM 100 Cloud-Init Results (Verified from /var/log/cloud-init.log):**
- ✅ Cloud-init v.25.1.4 completed all 4 stages
- ✅ User creation: sleszdockerugreen created with correct groups and sudo access
- ✅ Package installation: docker.io + docker-compose installed successfully
- ✅ SSH: Configured and working
- ✅ Final status: 26 modules with 0 failures
- ✅ Verification: `docker --version` returns Docker 28.2.2

**Why this works:**
- Proxmox passes user-data to cloud-init properly
- DataSourceNone is a fallback, but user-data still processes
- Package updates work reliably
- All configuration directives execute successfully

**Key Finding for Automation:** Cloud-init is 100% reliable - use it for automated VM creation

---

### ❌ What Does NOT Work

| Approach | Problem | Why | Solution |
|----------|---------|-----|----------|
| ISO + interactive install | CDROM unmount fails | UEFI/IDE bug (known hardware limitation) | Use cloud images or preseed |
| Guessing cloud-init config | Wrong datasource assumptions | Each hypervisor different | Always verify `/var/log/cloud-init.log` |
| Manual IDE2 workaround in automation | Timing issues, fragile | Can't reliably detect install completion | Use cloud images (NO ISO needed) |

---

### ✅ RECOMMENDED: Ubuntu Cloud Image Approach

**Why this is optimal for automation:**
1. **No ISO** → No CDROM device → No unmount bug
2. **Fully unattended** → No interactive installer
3. **Cloud-init proven reliable** → VM 100 confirms 100% success
4. **Fast** → System ready in ~10 seconds
5. **Repeatable** → Identical results every time

**Process:**
1. Download Ubuntu 24.04 cloud image (qcow2)
2. Convert to raw format for Proxmox
3. Create VM with cloud image as scsi0 disk (NO ide2)
4. Configure cloud-init via Proxmox `--cicustom` OR ConfigDrive
5. Boot → cloud-init executes → system ready
6. Verify via SSH: Docker running, packages installed

---

### 📋 Reference Configuration (VM 100 - Proven Working)

**Successful Proxmox VM Configuration:**
```
bios: ovmf                       # UEFI
machine: q35                     # Modern emulation
cores: 4
memory: 20480                    # 20GB RAM
scsi0: nvme2tb:vm-100-disk-1     # Main disk (250GB)
ide2: none,media=cdrom           # IDE2 disabled (THIS IS KEY!)
net0: virtio,bridge=vmbr0        # DHCP networking
boot: order=scsi0;ide2;net0      # Boot order (ide2 inactive)
```

**File Location:** `/etc/pve/qemu-server/100.conf`

---

### 🔧 Verification Commands (For Future Sessions)

**After VM creation, verify success with:**

```bash
# On Proxmox host
sudo qm config 100 | grep -E "bios|machine|ide|boot|scsi0"

# Inside VM via SSH
docker --version
docker-compose --version
apt list --installed | grep -E "docker|compose"
id $(whoami)
sudo cloud-init status --long
```

**All must show success or the automation failed.**

---

### 🚫 Rules to Follow (To Avoid Mistakes)

**WHEN CREATING VMs AUTOMATICALLY:**

1. ✅ **Use cloud images, NOT ISO**
   - Prevents CDROM unmount bug entirely
   - Faster and more reliable
   - No manual workarounds needed

2. ✅ **Always verify cloud-init.log after first boot**
   - Check: `/var/log/cloud-init.log`
   - Verify: User created, packages installed, SSH working
   - Don't assume success - test it

3. ✅ **Reference VM 100 config for BIOS/machine settings**
   - Don't try different firmware combinations
   - Use proven UEFI (ovmf) + q35 settings
   - Keep ide2 set to "none" (not attached to ISO)

4. ❌ **NEVER assume cloud-init failure without logs**
   - Log shows success ≠ everything actually installed
   - Verify with: `docker --version`, `apt list --installed`
   - DataSourceNone is normal on Proxmox, not an error

5. ❌ **NEVER use IDE device for CDROM in automation**
   - IDE + UEFI = unmount bug (known limitation)
   - Even with workaround, it's fragile and timing-dependent
   - Cloud images eliminate this entirely

6. ❌ **NEVER guess about datasource configuration**
   - Test actual behavior, not assumptions
   - Proxmox passes user-data via cloud-init
   - Trust the logs, not your theory

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
