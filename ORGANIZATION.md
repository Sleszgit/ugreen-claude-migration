# Home Directory Organization Guide

**Last Updated:** 2026-01-01
**Purpose:** Establish clear separation and collaboration structure for Claude + Gemini projects

---

## 📁 Directory Structure

```
/home/sleszugreen/
│
├── 📂 ai-projects/                    ← CLAUDE + GEMINI COLLABORATION
│   ├── homelab-automation/
│   │   ├── .ai_context/
│   │   ├── scripts/
│   │   ├── docs/
│   │   └── README.md
│   ├── infrastructure-tools/
│   ├── data-transfer/
│   ├── security-hardening/
│   └── SHARED-PROJECTS.md             ← Index of active collaborative projects
│
├── 📂 claude-solo/                    ← CLAUDE-ONLY PROJECTS
│   ├── proxmox-admin-tools/           (Proxmox management automation)
│   ├── container-management/          (LXC/VM management tools)
│   └── README.md
│
├── 📂 gemini-solo/                    ← GEMINI-ONLY ANALYSIS
│   ├── logic-audits/                  (Stored audit reports)
│   ├── security-reviews/              (Stored security analysis)
│   ├── architecture-analysis/         (Design decisions & evaluations)
│   └── README.md
│
├── 📂 scripts/                        ← UTILITY SCRIPTS (EXISTING)
│   ├── auto-update/
│   ├── infrastructure/
│   ├── services/
│   ├── git-utils/
│   ├── utility/                       ← Move loose home scripts here
│   └── README.md
│
├── 📂 docs/                           ← DOCUMENTATION (EXISTING)
│   ├── claude-sessions/
│   ├── hardware/
│   └── README.md
│
├── 📂 logs/                           ← LOG FILES (EXISTING)
│   ├── auto-update/
│   ├── services/
│   └── README.md
│
├── 📂 archives/                       ← COMPLETED/OLD PROJECTS
│   ├── completed-nas-transfer/        (Move from projects/)
│   ├── archived-proxmox-hardening/    (Move from projects/)
│   ├── archived-rada-reporter/        (Move when complete)
│   └── README.md
│
├── 📂 .ai_context/                    ← SHARED STATE (EXISTING)
│   ├── current_mission.tmp            (Active goal)
│   ├── decision_log.md                (Gemini consultation history)
│   └── collaboration_history.md       (Long-term patterns)
│
├── ORGANIZATION.md                    ← THIS FILE
├── CLAUDE.md                          ← Global collaboration rules (UPDATED)
└── .gitignore                         ← Version control exclusions
```

---

## 📋 Folder Rules

### `ai-projects/` - DEFAULT: Collaborative Projects
**Default Model:** All projects start here unless explicitly marked as solo
**Collaboration:** Claude (Strategic Lead) + Gemini (Expert Consultant)
**Structure:** Each project must have:
```
project-name/
├── .ai_context/                  ← Project-specific shared state
│   ├── current_mission.tmp
│   ├── decision_log.md
│   └── collaboration_history.md
├── src/ or scripts/
├── docs/
├── tests/
└── README.md                     ← Project overview & status
```

**Types of collaborative projects (all start here):**
- Infrastructure automation (planning + security review)
- Data transfer tools (strategy + edge case analysis)
- Security hardening (architecture + vulnerability assessment)
- Monitoring systems (design + performance optimization)
- Any project >50 lines, security-sensitive, or with multiple approaches
- Any project that will be tested/refined (default for most work)

### `claude-solo/` - Opt-In Solo Projects
**When:** Project explicitly marked as solo-only at start
**Criteria:** Must be marked "SOLO" in README at project creation
**Used for:**
- Simple CLI wrappers (qm/pct commands with no logic)
- One-time administrative utilities (no future maintenance)
- Straightforward management scripts (no complexity)
- Projects where Gemini review explicitly adds NO value (rare)

**Important:** Projects are collaborative by default. Solo is an exception that must be explicitly chosen.

**Example:**
```
claude-solo/
├── proxmox-admin-tools/
│   ├── vm-backup-manager.sh
│   ├── container-monitor.sh
│   └── README.md
```

### `gemini-solo/` - Gemini's Analysis Archive
**When:** Gemini produces reports/analysis not tied to active code
**Contains:**
- Security audit reports (from `! gemini -p "security audit"`)
- Logic analysis reports (from `! gemini -p "logic audit"`)
- Architecture evaluations
- Best practices documentation

**Format:** Each report is a markdown file with:
- Date created
- Code/files analyzed
- Findings
- Recommendations
- Status (implemented/pending/rejected)

### `scripts/utility/` - Loose Utility Scripts
**Purpose:** Move individual scripts from home directory here
**Examples:**
- checkpoint-verify.sh
- deploy-zfs-auto-import.sh
- enable-api-access.sh
- diagnostic tools
- one-off helpers

---

## 🚀 Migration Plan (Gradual)

**Phase 1: Documentation (Today)**
- ✅ Create ORGANIZATION.md (this file)
- ✅ Update CLAUDE.md with sections 6-10
- Create `scripts/utility/README.md`

**Phase 2: Initial Organization (This week)**
- Create empty folders: `ai-projects/`, `claude-solo/`, `gemini-solo/`, `archives/`
- Move loose home scripts to `scripts/utility/`
- Create `.ai_context/collaboration_history.md` template

**Phase 3: Ongoing Cleanup (As projects complete)**
- Move completed projects: `projects/nas-transfer/` → `archives/completed-nas-transfer/`
- Move archived projects: `projects/proxmox-hardening/` → `archives/archived-proxmox-hardening/`
- Delete empty skeleton folders from `projects/`

**Phase 4: Stabilization**
- All new collaborative work in `ai-projects/`
- All new Claude-only work in `claude-solo/`
- Archive old projects quarterly

---

## 📝 Project Template

When starting a new project, use this template:

```markdown
# [Project Name]

**Created:** YYYY-MM-DD
**Type:** [Collaborative / Claude-only / Gemini analysis]
**Status:** [In Progress / Blocked / Complete]
**Owner:** Claude

## Objective
Brief description of what this project does.

## Current Status
- [ ] Phase 1: Planning
- [ ] Phase 2: Development
- [ ] Phase 3: Testing
- [ ] Phase 4: Documentation

## Key Files
- `src/main_file.sh` - Primary script
- `.ai_context/decision_log.md` - Gemini consultation history

## Next Steps
1. ...
2. ...

## Notes
Any ongoing considerations or blockers.
```

---

## 🔄 Context File Template

Create `.ai_context/collaboration_history.md` in project root:

```markdown
# Collaboration History

## Purpose
Track patterns, lessons learned, and repeated issues across Gemini consultations.

## Patterns Observed
- **Issue Type:** [Security, Logic, Performance, etc.]
  - Frequency: X times
  - Root cause: ...
  - Prevention: ...

## Gemini Consultation Stats
- Total consultations: X
- Security audits: X
- Logic audits: X
- Architecture reviews: X
- Average findings per audit: X

## Lessons Learned
1. ...
2. ...

## Predictions for Next Work
Based on patterns, likely issues in next phase: ...
```

---

## ✅ Key Benefits

1. **Reduced Clutter:** Home directory has only active folders
2. **Clear Separation:** Easy to identify Claude vs Gemini vs Shared work
3. **Easy Scaling:** New projects follow consistent structure
4. **Better Continuity:** .ai_context in each project preserves history
5. **Strategic Clarity:** Visual organization reinforces role boundaries

---

## 🔗 Related Documents
- `CLAUDE.md` - Agent collaboration protocol (sections 6-10)
- `~/.claude/CLAUDE.md` - Global user instructions
- `.ai_context/decision_log.md` - Template in project .ai_context/
