# Claude Solo: Claude-Only Projects

**Purpose:** Projects where Claude leads design, implementation, and decisions without regular Gemini consultation

---

## 📂 Projects in This Category

### When to Use This Folder
- ✅ Straightforward utilities (no complex logic)
- ✅ Management scripts where strategy is clear
- ✅ Infrastructure tools with simple requirements
- ✅ Projects where Gemini review adds minimal value
- ❌ NOT for complex code (>50 lines with decision logic)
- ❌ NOT for security-sensitive operations
- ❌ NOT for code that failed 2+ times

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

## 🎯 Decision Rule

**Ask yourself:** "Is Gemini likely to find issues or suggest significant improvements?"

- **Yes?** → Move to `ai-projects/` (use collaboration model)
- **No?** → Keep in `claude-solo/` (Claude handles it)

---

## 🔗 Related Documentation
- `ORGANIZATION.md` - When to use each folder type
- `STRATEGIC-FRAMEWORK.md` - Role definitions

---

**Last Updated:** 2026-01-01
