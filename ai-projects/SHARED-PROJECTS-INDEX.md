# Shared Projects Index

**Purpose:** Quick reference for all collaborative Claude + Gemini projects

**Last Updated:** 2026-01-01

---

## 📊 Active Projects

| Project | Status | Purpose | Owner | Last Update |
|---------|--------|---------|-------|-------------|
| lxc102-backup-strategy | 🔄 Planning | Backup & recovery for LXC102 | Claude | 2026-01-01 |
| homelab-automation | ⏳ Template | Infrastructure automation | Claude | 2026-01-01 |
| infrastructure-tools | ⏳ Template | Proxmox/LXC utilities | Claude | 2026-01-01 |
| data-transfer | ⏳ Template | NAS/backup transfer | Claude | 2026-01-01 |
| security-hardening | ⏳ Template | Security hardening | Claude | 2026-01-01 |

---

## 🔍 Project Details

### lxc102-backup-strategy/ ⭐ ACTIVE
- **Full Path:** `~/ai-projects/lxc102-backup-strategy/`
- **Status:** 🔄 Planning Phase
- **Description:** Design and implement backup/recovery strategy for LXC102 (ugreen-ai-terminal)
- **Key Decisions:**
  - Backup method: vzdump vs snapshots vs rsync vs tar+SSH
  - Storage location: Homelab isolation vs UGREEN NAS redundancy
  - Frequency: On-demand, daily, or after changes
  - Recovery testing procedure
- **Next Step:** Consult Gemini on backup approaches
- **Key Files:**
  - `README.md` - Full objective & requirements
  - `.ai_context/current_mission.tmp` - Problem statement
  - `.ai_context/decision_log.md` - Tracking Gemini consultations

### homelab-automation/
- **Full Path:** `~/ai-projects/homelab-automation/`
- **Status:** ⏳ Template (ready to start)
- **Description:** Infrastructure automation scripts
- **Key Files:** See `.ai_context/decision_log.md`
- **Next Review:** When starting this project

### infrastructure-tools/
- **Full Path:** `~/ai-projects/infrastructure-tools/`
- **Status:** ⏳ Template (ready to start)
- **Description:** Proxmox and LXC management utilities
- **Key Files:** See `.ai_context/decision_log.md`
- **Next Review:** When starting this project

### data-transfer/
- **Full Path:** `~/ai-projects/data-transfer/`
- **Status:** ⏳ Template (ready to start)
- **Description:** NAS/backup data transfer automation
- **Key Files:** See `.ai_context/decision_log.md`
- **Next Review:** When starting this project

### security-hardening/
- **Full Path:** `~/ai-projects/security-hardening/`
- **Status:** ⏳ Template (ready to start)
- **Description:** Security hardening and protection scripts
- **Key Files:** See `.ai_context/decision_log.md`
- **Next Review:** When starting this project

---

## 📈 Collaboration Statistics

| Metric | Value |
|--------|-------|
| Total active projects | 4 |
| Total Gemini consultations | [Update as work progresses] |
| Average consultations per project | [Update as work progresses] |
| Issues found by Gemini | [Update as work progresses] |

---

## 🔄 Recent Gemini Consultations

[Update this as consultations happen]

| Date | Project | Issue | Finding | Status |
|------|---------|-------|---------|--------|
| [To fill] | [Project] | [Issue] | [Finding] | Implemented |

---

## 🎯 Quick Navigation

Start here to find information:

**Starting New Collaborative Work?**
- Read: `ai-projects/README.md`
- Use template from: `SHARED-PROJECTS-INDEX.md` → New Project Section

**Need Gemini Review?**
- Check: `STRATEGIC-FRAMEWORK.md` → Decision Tree
- Log output in: `.ai_context/decision_log.md`

**Looking for Old Analysis?**
- Check: `~/gemini-solo/[type]/` folders
- Pattern search: `.ai_context/collaboration_history.md`

**Project Complete?**
- Move to: `~/archives/completed-[project-name]/`
- Document in: `~/archives/ARCHIVE-INDEX.md`

---

## 📋 New Project Checklist

When adding a new collaborative project:

- [ ] Create folder in `~/ai-projects/new-project/`
- [ ] Create `.ai_context/` subfolder
- [ ] Copy collaboration templates (current_mission.tmp, decision_log.md, collaboration_history.md)
- [ ] Create `docs/` subfolder
- [ ] Create `docs/README.md` from template
- [ ] Add project to this index (SHARED-PROJECTS-INDEX.md)
- [ ] Create first commit: "Start project: new-project"
- [ ] Begin work with `current_mission.tmp` for tracking

---

## 🔗 Related Files

- `~/ai-projects/README.md` - Detailed collaboration guide
- `~/STRATEGIC-FRAMEWORK.md` - When to call Gemini
- `~/.ai_context/collaboration_history.md` - Global patterns & lessons
- `~/ORGANIZATION.md` - Folder structure overview

---

**Owner:** Claude Code
**Maintained By:** Claude Code
**Review Frequency:** Weekly (check for new projects, update status)
