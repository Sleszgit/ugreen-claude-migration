# SESSION 9 - CLAUDE CODE MIGRATION SETUP

**Date:** December 14, 2025
**Location:** LXC 102 (192.168.40.81)
**Topic:** Claude Code Migration from Proxmox Host (192.168.40.60)

---

## Background

A previous Claude Code instance was accidentally installed on the Proxmox host (192.168.40.60) instead of on LXC 102. Many problems were tackled and files were created during conversations with that instance. When the misplacement was discovered, an attempt was made to migrate everything to LXC 102, but it failed.

**Goal:** Complete the migration by retrieving critical files and configuration.

---

## Critical Finding: CLAUDE.md File Structure

### Discovery Process
The previous Claude instance on Proxmox created an important configuration file that contains:
- User preferences (prefer web UIs, plain language explanations)
- UGREEN infrastructure details (IPs, specs)
- Folder structure guidelines (~/projects/, ~/scripts/, ~/docs/, ~/logs/, ~/shared/)
- GitHub configuration (token for repo access)
- Command execution preferences

### Correct Location
**File must be placed at:** `~/.claude/CLAUDE.md`

This is the standard location where Claude Code looks for custom configuration and will automatically load it at the start of every conversation.

**NOT** in home directory (`~/CLAUDE.md`) - Claude Code doesn't search there.

---

## Current Status on LXC 102

### What Already Exists
1. **claude.md** at `/home/sleszugreen/claude.md` (created during this session)
   - This is a project-specific documentation guide
   - Points to hardening project files
   - Should be PRESERVED

2. **Documentation Index** at `/home/sleszugreen/DOCUMENTATION-INDEX.md`
   - Complete navigation of all local resources
   - Created during this session

3. **Session 8 Summary and related files** (from previous sessions on LXC 102)
   - Proxmox hardening project documentation
   - Project status files
   - SSH troubleshooting documentation

### What's Missing (On Proxmox Host)
1. **~/.claude/CLAUDE.md** (CRITICAL - must retrieve)
2. **~/projects/** directory (working code and projects)
3. **~/scripts/** directory (automation scripts)
4. **~/.claude/skills/** directory (custom skills)
5. **~/.claude/plans/** directory (saved plans)
6. **~/.claude/plugins/** directory (custom plugins)
7. **~/.claude/session-env/** directory (26 conversation sessions)

---

## Conversation Count Issue

**Reported:** 26 conversations in Proxmox instance
**Found on LXC 102:** ~38 conversation files (includes agent sub-conversations)
**Status:** Partial migration may have already occurred, or counts are different

---

## Files NOT to Copy (Security)
- `~/.claude/.credentials.json` (authentication tokens)
- `~/.claude/.credentials.jso` (backup credentials file)
- `~/.claude/history.jsonl` (keep separate per instance)

---

## Next Immediate Action Required

### SSH Access to Proxmox
To retrieve files via SCP, need confirmation of:
1. **Username for Proxmox access** (root? sleszugreen? other?)
2. **Authentication method:**
   - SSH key already configured?
   - Password-based SSH?
   - What password/key?

### Command to Execute
Once SSH confirmed:
```bash
mkdir -p ~/.claude
scp <USER>@192.168.40.60:~/.claude/CLAUDE.md ~/.claude/CLAUDE.md
```

---

## Updated Documentation System

Created comprehensive documentation structure:

1. **claude.md** - Session instructions & documentation locations
2. **DOCUMENTATION-INDEX.md** - Complete navigation index
3. **PROXMOX-HARDENING-CURRENT-STATUS.md** - Project status
4. **CLAUDE-CODE-CONTEXT-FOR-LXC102.md** - Technical context
5. **SESSION-8-SUMMARY.md** - Latest session summary
6. **README-SESSION-8.txt** - Quick reference card
7. **SESSION-7-SSH-TROUBLESHOOTING.md** - SSH issue documentation

---

## Implementation Plan (Awaiting SSH Credentials)

**Phase 1: Retrieve CLAUDE.md** (BLOCKED - needs SSH info)
1. Connect to Proxmox host via SSH
2. Retrieve ~/.claude/CLAUDE.md
3. Place at ~/.claude/CLAUDE.md on LXC 102
4. Verify file integrity

**Phase 2: Selective Recovery** (After Phase 1)
1. Copy ~/projects/ directory
2. Copy ~/scripts/ directory
3. Copy ~/.claude/skills/ directory
4. Copy ~/.claude/plans/, plugins/, session-env/

**Phase 3: Verification** (After Phase 2)
1. Verify all files copied
2. Check permissions preserved
3. Update claude.md with LXC 102 paths
4. Document recovered resources

**Phase 4: Finalization** (After Phase 3)
1. Create recovery completion report
2. Mark Proxmox instance as "read-only archive"
3. Make LXC 102 the single source of truth

---

## Key Decisions Made This Session

1. ✅ Identified correct location for CLAUDE.md: `~/.claude/CLAUDE.md`
2. ✅ Created documentation index and navigation system
3. ✅ Preserved existing claude.md (project-specific guide)
4. ✅ Documented migration requirements and security considerations
5. ⏳ **BLOCKED** - Awaiting SSH credentials to retrieve Proxmox files

---

## Current Blockers

1. **SSH Access Credentials**
   - Need username for Proxmox
   - Need authentication method (key/password)
   - Cannot proceed with file retrieval without this

2. **Conversation History**
   - Migration summary mentions 26 sessions on Proxmox
   - Current instance shows ~38 files
   - Discrepancy needs clarification

---

## Files Modified/Created This Session

1. `/home/sleszugreen/claude.md` - Updated with documentation locations and access procedures
2. `/home/sleszugreen/DOCUMENTATION-INDEX.md` - Created comprehensive index
3. `/home/sleszugreen/SESSION-9-CLAUDE-MIGRATION-PLAN.md` - This file

---

## Notes for Next Session

- This is a blocked state waiting for SSH credentials
- When credentials provided, migration can proceed automatically
- All planning is complete, ready to execute
- Previous claude.md from Proxmox is the highest priority item
- This session focused on understanding the problem and planning, not execution

---

## Contact Information

- **Proxmox Host:** 192.168.40.60
- **LXC 102 Container:** 192.168.40.81
- **Target File:** Proxmox `~/.claude/CLAUDE.md` → LXC 102 `~/.claude/CLAUDE.md`
