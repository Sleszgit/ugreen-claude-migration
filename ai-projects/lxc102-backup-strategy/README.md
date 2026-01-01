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

- [x] Phase 1: Research backup methods & compare approaches
- [x] Phase 2: Design backup strategy (with Gemini input on multiple approaches)
- [ ] Phase 3: Implement backup scripts
- [ ] Phase 4: Test recovery procedure
- [ ] Phase 5: Set up automated scheduling
- [ ] Phase 6: Document and deploy

---

## ✅ APPROVED STRATEGY (Decision: 2026-01-01)

**Primary Backup: Daily Vzdump → Homelab**
- Time: 2 AM (off-peak)
- Method: Proxmox native full container backup
- Destination: Homelab NFS mount
- Retention: 10 backups (7 daily + 1 weekly + 2 archive)
- Size: ~30GB total (~2-3GB per backup)
- Restore time: 5-10 minutes
- Purpose: Complete disaster recovery, bare metal rebuild

**Secondary Backup: Daily Rsync → UGREEN NAS**
- Time: 3 AM (after work, off-peak)
- Method: SSH + rsync incremental sync
- Destination: /storage/Media/backups/lxc102-rsync/
- Protected files: ~/scripts/, ~/projects/, ~/.bashrc, ~/.ssh/, ~/.local/bin/
- Retention: 7 daily snapshots
- Size: ~5GB (one day's changes)
- Restore time: Minutes (file-level recovery)
- Purpose: Quick recovery from config corruption/accidental delete

**Foundation: GitHub**
- Frequent commits (ongoing, work-in-progress)
- Session documentation
- Version control for all tracked work

**Rationale:**
- Protects against: Crashes during work + system corruption
- GitHub handles frequent commits; daily snapshot sufficient for system state
- Redundant locations provide defense in depth
- Daily Rsync on UGREEN NAS for quick recovery; Daily Vzdump on Homelab for disaster recovery

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
- [Complete] Initial planning and framework setup
- [Complete] Research backup methods and compare approaches
- [Complete] Proposed strategy to user (Gemini unavailable - quota hit; Claude strategic analysis)
- [Complete] Received user feedback on frequency (hourly vs daily)
- [Complete] Refined recommendation to daily rsync
- [Complete] User approved: "Go with daily rsync (your recommendation)"
- [Complete] Updated decision log with APPROVED status
- Next: Phase 3 - Create backup scripts
