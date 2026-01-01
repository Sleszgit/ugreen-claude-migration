# Archives: Completed & Old Projects

**Purpose:** Store completed projects and archived work (removed from active use)

---

## 📂 Archive Categories

### **completed-[project-name]/**
Projects that are:
- ✅ Fully implemented
- ✅ Thoroughly tested
- ✅ Documented and stable
- ✅ No active development planned
- Example: `completed-nas-transfer/`

### **archived-[project-name]/**
Projects that are:
- 📋 Superseded by newer versions
- 🔄 On indefinite hold
- 🧪 Experimental (didn't go to production)
- 📚 Historical (kept for reference)
- Example: `archived-proxmox-hardening/` (if replaced by newer system)

---

## 🏷️ Naming Convention

```
completed-[project-name]/        ← Fully done, stable, can be referenced
archived-[project-name]/         ← Old, superseded, or experimental

Examples:
  completed-nas-transfer/
  archived-first-attempt-backup-system/
  completed-lxc102-security-hardening/
```

---

## 📋 When to Move Project Here

Move from `ai-projects/` or `claude-solo/` when:
- ✅ All work items complete
- ✅ No bugs reported in 2+ weeks
- ✅ Documentation finalized
- ✅ No active maintenance planned
- ✅ Not expected to resume in next 3 months

---

## 📝 Archive Documentation

Keep an `ARCHIVE-INDEX.md` at root to track all archived projects:

```markdown
# Archive Index

## Completed Projects
| Project | Completed | Purpose | Notes |
|---------|-----------|---------|-------|
| nas-transfer | 2025-12-20 | Synology → UGREEN backup | Working, stable, can reference |
| monitoring-setup | 2025-11-15 | LXC 102 stability monitor | In production, periodic maintenance |

## Archived/Experimental
| Project | Archived | Reason | Notes |
|---------|----------|--------|-------|
| first-attempt-hardening | 2025-10-01 | Replaced by improved version | Do not use - outdated approach |
| zfs-replication-poc | 2025-09-15 | Experimental | Proof of concept, not production |
```

---

## 🔍 Reference & Learning

Archives are valuable for:

1. **Historical Reference**
   - How did we solve X problem before?
   - What was the old approach?

2. **Pattern Recognition**
   - What issues appeared in old projects?
   - How did we handle them?

3. **Documentation**
   - Keep session notes explaining why archived
   - Helps future decisions

4. **Reusable Code**
   - Can we adapt old solution to new problem?

---

## 🚫 What NOT to Archive

- ❌ Incomplete projects (use `~/projects/` for holding)
- ❌ Work-in-progress (keep in active folders)
- ❌ Temporary scripts (<1 week lifespan)

---

## 🔄 Moving Project to Archives

### From ai-projects/
```bash
# 1. Final documentation
cd ~/ai-projects/my-project
# → Add final session notes to docs/SESSIONS.md

# 2. Mark completion
# → Update status in README.md to "Complete"

# 3. Move to archives
mv ~/ai-projects/my-project ~/archives/completed-my-project

# 4. Git commit
git add archives/completed-my-project/
git commit -m "Archive: completed-my-project - stable and documented"
```

### From claude-solo/
```bash
# Similar process, archive as needed
mv ~/claude-solo/old-tool ~/archives/completed-old-tool
```

---

## 💾 Storage Strategy

Archives can accumulate over time. Quarterly:
- Review archive list (ARCHIVE-INDEX.md)
- Identify projects with zero references
- Consider moving to external storage if needed
- Keep current year actively available

---

## 🔗 Related Documentation
- `ORGANIZATION.md` - Folder structure overview
- `ai-projects/README.md` - Starting new projects

---

**Last Updated:** 2026-01-01
