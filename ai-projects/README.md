# AI Projects: Claude + Gemini Collaboration Zone

**Purpose:** Active projects where Claude (Strategic Lead) and Gemini (Tactical Expert) collaborate

---

## 📂 Active Projects

### 1. **homelab-automation/**
- **Status:** [To be filled]
- **Purpose:** Infrastructure automation scripts and tools
- **Collaboration Model:** Claude leads design; Gemini reviews for edge cases
- **Owner:** Claude
- **Last Updated:** [To be filled]

**Key Files:**
- `.ai_context/` - Project state and decision log
- `docs/` - Project documentation
- `scripts/` - Automation scripts

---

### 2. **infrastructure-tools/**
- **Status:** [To be filled]
- **Purpose:** Proxmox/LXC management utilities
- **Collaboration Model:** Claude leads implementation; Gemini security audits
- **Owner:** Claude
- **Last Updated:** [To be filled]

---

### 3. **data-transfer/**
- **Status:** [To be filled]
- **Purpose:** NAS/backup data transfer automation
- **Collaboration Model:** Claude manages workflow; Gemini audits logic
- **Owner:** Claude
- **Last Updated:** [To be filled]

---

### 4. **security-hardening/**
- **Status:** [To be filled]
- **Purpose:** Security and hardening scripts
- **Collaboration Model:** Claude executes; Gemini performs security reviews
- **Owner:** Claude
- **Last Updated:** [To be filled]

---

## 📋 Project Structure Template

Each project should follow this structure:

```
project-name/
├── .ai_context/
│   ├── current_mission.tmp        ← Active task statement
│   ├── decision_log.md            ← Gemini consultation history
│   └── collaboration_history.md   ← Long-term patterns
├── docs/
│   ├── README.md                  ← Project overview
│   ├── ARCHITECTURE.md            ← Design decisions
│   └── SESSIONS.md                ← Session notes
├── scripts/
│   └── [script files]
├── tests/
│   └── [test files]
└── .gitignore
```

---

## 🚀 Starting a New Collaborative Project

### Step 1: Create Project Folder
```bash
mkdir ~/ai-projects/my-project
cd ~/ai-projects/my-project
```

### Step 2: Set Up .ai_context
```bash
mkdir .ai_context
# Copy templates from ~/.ai_context/
cp ~/.ai_context/collaboration_history.md .ai_context/
touch .ai_context/current_mission.tmp
touch .ai_context/decision_log.md
```

### Step 3: Create Initial Documentation
```bash
# Create project README with template (see below)
touch docs/README.md
touch docs/ARCHITECTURE.md
touch docs/SESSIONS.md
```

### Step 4: Begin Development
- Claude leads strategic decisions
- Consult Gemini when: complexity >50 lines, code fails 2+ times, security concerns exist
- Log all Gemini consultations in `.ai_context/decision_log.md`

---

## 📝 Project README Template

```markdown
# [Project Name]

**Created:** YYYY-MM-DD
**Type:** Collaborative
**Status:** [In Progress / Blocked / Complete]
**Owner:** Claude

## Objective
Clear description of what this project achieves.

## Progress
- [ ] Phase 1: Planning & architecture
- [ ] Phase 2: Implementation
- [ ] Phase 3: Testing & validation
- [ ] Phase 4: Documentation & deployment

## Key Components
- Component 1: [Description]
- Component 2: [Description]

## Gemini Consultations
- [Date]: Issue → Recommendation → Status
- See `.ai_context/decision_log.md` for full history

## Next Steps
1. ...
2. ...

## Known Issues
- Issue 1: [Description & workaround]
```

---

## 🔄 Collaboration Workflow

### When Claude Needs Gemini
```bash
# 1. Document the task
echo "Review backup verification logic for race conditions" > .ai_context/current_mission.tmp

# 2. Call Gemini
! gemini -p "Perform logic audit. Look for race conditions, edge cases, off-by-one errors." backup-verify.sh

# 3. Review output (Markdown format expected)
# - Analysis section: What was examined
# - Findings section: Issues found
# - Recommendations section: How to fix
# - Implementation tips: Code examples

# 4. Document in decision log
# Date | File | Issue | Gemini Recommendation | Status (Implemented/Pending/Rejected)
```

### Decision Log Format
```
| Date | File | Issue | Gemini Recommendation | Action | Status |
|------|------|-------|----------------------|--------|--------|
| 2026-01-01 | backup-verify.sh | Race condition in loop | Use flock for file locking | Implemented | ✅ |
```

---

## 📊 When to Archive

Move project to `~/archives/` when:
- Development is complete
- Project is stable and tested
- No active work planned in next 3 months
- All documentation finalized

**Archive naming:** `completed-[project-name]/` or `archived-[project-name]/`

---

## 🔗 Related Documentation
- `STRATEGIC-FRAMEWORK.md` - When/how to use Gemini
- `ORGANIZATION.md` - Folder structure explanation
- `CLAUDE.md` - Detailed collaboration protocol (sections 6-10)
- `.ai_context/collaboration_history.md` - Global patterns & lessons

---

**Last Updated:** 2026-01-01
