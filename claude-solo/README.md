# Claude Solo: Opt-In Solo Projects

**Purpose:** Projects explicitly marked as solo-only where Claude leads design, implementation, and decisions without Gemini consultation

**⚠️ IMPORTANT:** This is NOT the default! Projects are collaborative by default.
Only create solo projects if you explicitly mark them as such at creation time.

---

## 📂 Projects in This Category

### When to Create a Solo Project
You must EXPLICITLY choose solo when creating the project. Solo projects are rare exceptions.

**✅ Only use this folder if:**
- Project is extremely simple (no decision logic, <10 lines of wrapping code)
- One-time administrative utility (will never be revisited or refined)
- Trivial CLI wrapper (no custom logic)
- Marked "SOLO" in README at project creation
- Gemini review would literally add zero value

**❌ DO NOT use solo for:**
- Complex code (>50 lines)
- Security-sensitive operations (always get second opinion)
- Projects that failed 2+ times (need expert analysis)
- Anything that might be refined or expanded
- Any project without explicit "SOLO" marking at creation

**Default:** If unsure, put in ai-projects/ (collaborative) instead!

---

## 🚀 Project Examples

### **proxmox-admin-tools/**
- Proxmox VM/container management utilities
- Simple CLI wrappers around qm/pct commands
- Claude owns full lifecycle

### **container-management/**
- LXC container lifecycle scripts
- Backup/restore utilities
- One-off administrative tools

---

## 📁 Folder Structure

```
project-name/
├── docs/
│   └── README.md
├── scripts/
│   └── [script files]
└── .gitignore
```

**Note:** No `.ai_context/` folder needed (this is Claude-only)

---

## 📝 Project README Template

```markdown
# [Project Name]

**Created:** YYYY-MM-DD
**Type:** Claude-Solo
**Status:** [In Progress / Complete]
**Owner:** Claude

## Purpose
What this project does.

## Implementation Strategy
High-level approach (why Gemini not needed).

## Key Files
- `scripts/main-script.sh` - Primary utility

## Usage
How to use this project.

## Known Limitations
Any constraints or edge cases.
```

---

## 🎯 Decision Rule (Opt-In Solo Model)

**Default:** Start ALL projects in `ai-projects/` (collaborative)

**Only move to `claude-solo/` if you explicitly answer:**

**Question:** "Will I NEVER benefit from Gemini's analysis on this project?"

- **ANY doubt?** → Keep in `ai-projects/` (default, collaborative)
- **100% certain solo?** → Move to `claude-solo/` and mark "SOLO" in README

**Remember:** Solo is opt-in, not default. When in doubt, collaborate!

---

## 🔗 Related Documentation
- `ORGANIZATION.md` - When to use each folder type
- `STRATEGIC-FRAMEWORK.md` - Role definitions

---

**Last Updated:** 2026-01-01
