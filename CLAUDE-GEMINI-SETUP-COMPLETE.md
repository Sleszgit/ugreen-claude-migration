# Claude + Gemini Integration Setup - COMPLETE

**Status:** ✅ Framework established and documented
**Date:** 2026-01-01
**Next Step:** Begin gradual migration of projects to new folder structure

---

## 📋 What Was Updated

### 1. **CLAUDE.md** - Enhanced with 5 new sections
   - **Section 6:** Gemini output expectations (Markdown format, structured)
   - **Section 7:** Decision tree for when to call Gemini
     - ✅ CALL IF: Code >50 lines OR failed 2+ times
     - ❌ DON'T CALL IF: Simple code UNLESS failed 2+ times
   - **Section 8:** Context storage rules (.ai_context/)
   - **Section 9:** Error handling & fallback strategy
   - **Section 10:** Role definitions (Claude = Strategic Lead, Gemini = Tactical Expert)

### 2. **ORGANIZATION.md** - New folder structure guide
   - Clear separation: ai-projects (collaborative), claude-solo, gemini-solo, archives
   - Templates for each project type
   - Migration plan (phased approach)
   - Benefits and rationale

### 3. **.ai_context/collaboration_history.md** - Template created
   - Tracks Gemini consultation stats
   - Documents patterns observed
   - Records lessons learned
   - Token budget tracking

### 4. **STRATEGIC-FRAMEWORK.md** - New practical guide
   - Core strategy overview
   - Practical triggers with examples
   - Workflow example (backup verification script)
   - Token management strategy
   - Weekly/monthly review process
   - Pre-call checklist

---

## 🎯 Key Decisions Established

### Output Format
- **Gemini output:** Markdown with sections (Analysis | Findings | Recommendations | Implementation Tips)
- **Why:** Human-readable, parseable, fits in documentation naturally

### When to Call Gemini
1. Code >50 lines
2. **Code already failed 2+ times** (critical rule - try-before-escalate threshold)
3. Security-sensitive operations
4. Multiple valid approaches exist
5. Before major refactor/deployment

### Strategic Role Split
- **CLAUDE** (You): Leading AI on strategy, planning, final decisions
- **GEMINI:** Expert consultant on technical depth, called when strategic lead decides it adds value

### Token Management
- Track all calls in decision_log.md
- Batch similar reviews to improve efficiency
- Check history before calling (don't audit same code twice)
- Both plans are paid but NOT infinite - use strategically

---

## 📁 New Folder Structure (To Implement)

```
/home/sleszugreen/
├── ai-projects/           ← Claude + Gemini collaboration
├── claude-solo/           ← Claude-only projects
├── gemini-solo/           ← Gemini analysis archive
├── scripts/
│   └── utility/           ← Loose home scripts move here
├── docs/
├── logs/
├── archives/              ← Completed projects
└── .ai_context/           ← Shared state (NEW: collaboration_history.md added)
```

---

## ✅ Implementation Checklist

**Phase 1: Documentation (COMPLETE)**
- ✅ Update CLAUDE.md with sections 6-10
- ✅ Create ORGANIZATION.md
- ✅ Create .ai_context/collaboration_history.md
- ✅ Create STRATEGIC-FRAMEWORK.md
- ⏳ Commit to git

**Phase 2: Initial Organization (Next session)**
- ⏳ Create empty folders: ai-projects/, claude-solo/, gemini-solo/, archives/
- ⏳ Create scripts/utility/ folder
- ⏳ Move loose home scripts to scripts/utility/

**Phase 3: Ongoing (As projects complete)**
- ⏳ Move completed projects to archives/
- ⏳ Delete empty skeleton folders

**Phase 4: Stabilization (Ongoing)**
- ⏳ All new work follows folder structure
- ⏳ Weekly review of collaboration_history.md
- ⏳ Monthly token budget check

---

## 🚀 How to Use This Framework

### Starting a New Collaborative Project
```bash
# 1. Create in ai-projects/
mkdir ~/ai-projects/my-project
cd ~/ai-projects/my-project

# 2. Create .ai_context/
mkdir .ai_context
# Copy template from ~/.ai_context/collaboration_history.md

# 3. Begin work
# Claude leads strategy, calls Gemini when needed
```

### Consulting Gemini (Example)
```bash
# 1. Create mission statement
echo "Task: Review backup verification logic for edge cases" > .ai_context/current_mission.tmp

# 2. Call Gemini
! gemini -p "Perform rigorous logic audit. Look for edge cases, race conditions, off-by-one errors." backup-verify.sh

# 3. Document outcome
# Add to .ai_context/decision_log.md:
# Date | backup-verify.sh | Edge case handling | Use quoted vars | Fixed

# 4. Implement & test
# (Your code execution)
```

### Tracking Patterns
- Update .ai_context/collaboration_history.md with new patterns
- Weekly: Review for repeated issues
- Monthly: Adjust strategy based on findings

---

## 📚 Reference Guide

| Document | Purpose | When to Read |
|----------|---------|--------------|
| CLAUDE.md (updated) | Detailed collaboration protocol | When you need exact rules |
| ORGANIZATION.md | Folder structure explanation | When creating new projects |
| STRATEGIC-FRAMEWORK.md | Practical strategy & workflows | Before starting major work |
| .ai_context/collaboration_history.md | Pattern tracking template | Weekly sync |
| CLAUDE-GEMINI-SETUP-COMPLETE.md | This file - overview | Onboarding new projects |

---

## 🔍 What Changed From Original CLAUDE.md

**Added (Sections 6-10):**
- Output format specification (Markdown)
- When to call decision tree
- Context storage rules
- Error handling procedures
- Role definitions & strategic framework

**Key Enhancement:**
- **"Failed 2+ times" trigger** added to both CALL and DON'T CALL rules
- This creates a practical try-before-escalate workflow

**Key Principle:**
- Claude leads strategy; Gemini consulted for specific technical depth
- Not "AI debate" but "expert consultation within human-led strategy"

---

## 🎓 Learning & Iteration

This framework is **not static**. As you use Claude + Gemini:
1. Track what works in decision_log.md
2. Identify patterns in collaboration_history.md
3. Adjust triggers and rules based on actual results
4. Document lessons learned monthly

**Question to self:** "Are Gemini calls consistently valuable, or should I adjust when I call?"

---

## 📞 Questions & Next Steps

**Ready to proceed?**
1. Review the 4 new/updated documents above
2. Verify the framework makes sense
3. In next session: Start Phase 2 (folder creation & migration)

**Concerns or adjustments needed?**
- Any section that needs clarification?
- Any trigger rules that feel wrong?
- Any role definitions that need adjustment?

---

**Created by:** Claude Code (Strategic Lead)
**Reviewed with:** User input on output formats, error handling, context limits, practical examples
**Status:** Ready for implementation
