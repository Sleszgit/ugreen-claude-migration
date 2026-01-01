# LXC102 Backup Strategy

**Created:** 2026-01-01
**Type:** Collaborative
**Status:** Planning Phase
**Owner:** Claude (Strategic Lead)
**Project Goal:** Protect LXC102 (ugreen-ai-terminal) against data loss

---

## 🎯 Objective

Create a robust backup and snapshot strategy for LXC102 to protect the work done on:
- Auto-update system scripts
- Infrastructure management tools
- Security hardening scripts
- Claude Code configuration
- Gemini CLI installation
- All customizations and configurations

**Risk:** Losing LXC102 setup means losing months of configuration and scripting work.

---

## 📋 Decision Framework

**Available Storage Options:**
1. Homelab (192.168.40.40) - Separate physical location
2. UGREEN NAS (/storage/Media or other location)
3. Both (redundancy)

**Key Questions to Answer (with Gemini):**
1. What's the best backup method for LXC102? (vzdump, LVM snapshots, rsync, tar+SSH?)
2. How often should we backup? (daily, weekly, after major changes?)
3. Where's the optimal location? (homelab isolation, UGREEN redundancy, both?)
4. How do we verify backup integrity?
5. What's the recovery procedure if LXC102 fails?

---

## 📊 Current Status

- [ ] Phase 1: Research backup methods & compare approaches
- [ ] Phase 2: Design backup strategy (with Gemini input on multiple approaches)
- [ ] Phase 3: Implement backup scripts
- [ ] Phase 4: Test recovery procedure
- [ ] Phase 5: Set up automated scheduling
- [ ] Phase 6: Document and deploy

---

## 🔄 Collaboration Model

**Claude Role:**
- Research available backup methods
- Design strategy based on requirements
- Execute implementation
- Test and refine

**Gemini Role:**
- Compare backup approaches (trade-offs: speed vs redundancy, storage vs network load)
- Verify script logic for edge cases
- Security review of access patterns and credentials
- Architecture review before implementation

---

## 📁 Project Structure

```
lxc102-backup-strategy/
├── .ai_context/
│   ├── current_mission.tmp        ← Active task statement
│   ├── decision_log.md            ← Gemini consultations
│   └── collaboration_history.md   ← Pattern tracking
├── docs/
│   ├── README.md                  ← This file
│   ├── ARCHITECTURE.md            ← Design decisions
│   └── SESSIONS.md                ← Work progress
├── scripts/
│   ├── backup-lxc102.sh          ← Main backup script
│   ├── restore-lxc102.sh         ← Recovery script
│   └── verify-backup.sh          ← Integrity checking
└── tests/
    └── test-backup-recovery.sh   ← Recovery testing
```

---

## 🚀 Next Immediate Steps

1. **Research backup methods** (This session)
   - Investigate Proxmox backup options
   - Understand LXC102 structure and data
   - Identify dependencies

2. **Consult Gemini** (This session)
   - Multiple approaches comparison
   - Trade-off analysis
   - Recommendations

3. **Design backup strategy** (Next session)
   - Choose method and location
   - Plan scheduling
   - Document recovery procedure

---

## 💾 Critical Data to Protect

**Must preserve:**
- ~/.bashrc, ~/.bash_profile, ~/.bash_aliases
- ~/.ssh/
- ~/.local/bin/ (any installed tools)
- ~/scripts/ (all utility scripts)
- ~/projects/ (if any active)
- ~/.claude/ (configuration)
- ~/.gemini/ (configuration)
- /root/.ssh/ and root configs
- System packages list

---

## 🔗 Related Documentation

- Proxmox: `~/.claude/CLAUDE.md` - API & command reference
- Infrastructure: `INFRASTRUCTURE.md` - Network & storage setup
- LXC102 specifics: Will document as we learn

---

## 📝 Session Notes

### Session 1 (2026-01-01)
- [In Progress] Initial planning and framework setup
- Next: Research backup methods and consult Gemini
