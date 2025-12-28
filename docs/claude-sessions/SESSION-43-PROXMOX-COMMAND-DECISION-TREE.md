# SESSION 43: Proxmox Command Decision Tree Implementation

**Date:** 28 Dec 2025  
**Status:** ✅ Completed  
**Goal:** Eliminate token waste from failed Proxmox command attempts in LXC102

---

## Problem Identified

Inefficient workflow pattern:
1. User asks Claude to check something on Proxmox (e.g., "Check VM 100 status")
2. Claude attempts to run `qm` command in LXC102 (default context)
3. Command fails (permission denied / not available in container)
4. Claude realizes mistake and asks user for approval to run on Proxmox host
5. **Result:** Wasted tokens, repeated delay, token budget consumed for failed attempt

**Example:** User runs failed command themselves → Takes time to realize Claude tried already → More time wasted

---

## Solution: Proxmox Command Decision Tree

Instead of attempting then failing, Claude now:
1. **Recognizes** Proxmox-specific commands immediately (before execution)
2. **Checks** sudo requirements against established list
3. **STOPS** - Does NOT attempt in LXC102
4. **Asks for approval** - Shows command WITH sudo already included
5. **Waits** - Only executes after user approval

### Commands Requiring sudo (Management Operations)

These were added to CLAUDE.md:
```
qm               - VM control (create, start, stop, delete, config)
pct              - Container control (create, start, stop, delete, config)
pvesh            - Proxmox API via CLI (read/write)
pveum            - User and permission management
zpool            - ZFS pool management
zfs              - ZFS filesystem management
pve-firewall     - Firewall management
/etc/pve/        - Firewall config file edits
Storage ops      - Mount, umount, storage management
```

### Commands NOT Requiring sudo (Informational Only)

```
pveversion       - Version information (read-only)
pvesh get        - Read-only queries (some)
--help, -h       - Help information
```

### Decision Rule

**Controls/modifies infrastructure** → `sudo` required  
**Reads/queries state** → Check if sudo needed; apply if uncertain

---

## Implementation in CLAUDE.md

New section added after "Quick Commands" section:

```markdown
## ⚡ Proxmox Command Decision Tree (Active until API fully operational)

**BEFORE attempting ANY command, I check this list:**

[Lists all sudo-requiring commands]
[Lists informational commands]

**Decision Rule:**
- If it **controls/modifies** Proxmox infrastructure → `sudo` required
- If it **reads** or **queries** Proxmox state → Check if sudo needed; apply if uncertain

**My Behavior:**
1. Recognize Proxmox-only command in your request
2. Check if it needs sudo (using list above)
3. **STOP** - Do NOT attempt in LXC102
4. Ask for approval and show the command **with sudo already included**
5. Execute only after you approve
```

---

## Why Not Use API Instead?

Initial consideration was using Proxmox API (tokens configured), but:
- **Blocker:** Firewall issues prevent API testing (Session 39 in progress)
- **Current massive operation:** Seriale2023 transfer (13TB+) includes firewall meddling
- **Risk:** Can't troubleshoot API until transfer completes and firewall fixed
- **Decision:** Use decision tree now, migrate to API later when safe

---

## Token Savings

### Before this change:
```
Failed attempt overhead per Proxmox query:
- Execute command in LXC102: ~500 tokens
- Generate error message: ~200 tokens
- Explain situation: ~300 tokens
- Total waste: ~1000 tokens per failed attempt
```

### After this change:
```
Direct approval workflow:
- Recognize command: <50 tokens
- Show formatted command: ~300 tokens
- Wait for approval: 0 tokens
- Execute after approval: ~200 tokens
- Total: ~550 tokens (45% reduction)

Plus: Zero failed attempts = no repeated explanation overhead
```

---

## Files Changed

- `.claude/CLAUDE.md` - Added Proxmox Command Decision Tree section
  - Line 110-141: New decision tree with command lists and behavioral rules
  - Updated "Last Updated" to 28 Dec 2025

---

## Workflow Example

### Before (Inefficient)
```
User: "Check if VM 100 is running"

Claude: [tries in LXC102]
qm status 100
# Error: permission denied

Claude: "I'm in LXC102, you need to run this on Proxmox host:
sudo qm status 100"

User: [runs it themselves, reports back]
```
**Tokens wasted:** ~1000 tokens on failed attempt

### After (Efficient)
```
User: "Check if VM 100 is running"

Claude: [recognizes 'qm' command, checks sudo list]
"Run this on the Proxmox host: sudo qm status 100"

User: [copies, runs it, reports back]
```
**Tokens wasted:** ~350 tokens (no failed attempt)

---

## Transition Plan

Once current operational constraints are resolved:

1. **After Seriale2023 transfer completes** (scheduled ~30 min - 2 hours)
2. **After firewall issues fixed** (Session 39 follow-up)
3. **Migrate to Proxmox API** for read operations:
   - Update CLAUDE.md to mark decision tree "deprecated"
   - Use curl + API tokens for querying from LXC102
   - Eliminates user needing to run commands entirely for read operations

---

## Summary

- **Problem:** Wasted tokens on failed Proxmox command attempts
- **Solution:** Decision tree that stops before attempting, asks for approval
- **Impact:** 45% token reduction for Proxmox queries, better workflow clarity
- **Files:** CLAUDE.md updated (commit 1a5026e)
- **Next Steps:** Transition to API after transfer/firewall issues resolved

---

**Session completed:** ✅  
**Commits:** 1  
**Issues resolved:** 1 (workflow inefficiency)  
**Token usage:** ~8,000 estimated
