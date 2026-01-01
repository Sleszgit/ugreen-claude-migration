# Strategic Framework: Claude + Gemini Collaboration

**Created:** 2026-01-01
**Purpose:** Define clear strategy for when, how, and why Claude and Gemini work together

---

## 🎯 Core Strategy

### Role Split
- **CLAUDE** = Strategic Lead (you)
  - Decides approach and architecture
  - Executes code and manages projects
  - Owns final responsibility
  - **Leads on strategy and planning decisions**

- **GEMINI** = Tactical Expert (assistant)
  - Provides deep technical analysis when requested
  - Finds edge cases, security issues, complexity problems
  - Proposes alternatives, doesn't decide
  - **Follows Claude's strategic direction**

### Decision Flow
```
User Request
    ↓
Claude analyzes → "Can I handle this alone?"
    ↓
Yes → Execute directly (no Gemini call)
No → Consult Gemini → Integrate findings → Execute
```

---

## 🚀 When to Call Gemini (Practical Triggers)

### Automatic Trigger: Code Already Failed 2+ Times
**Rule:** If you've tried something twice and failed, call Gemini before attempt 3.
```
Attempt 1: Fails
Attempt 2: Still fails
→ STOP: "! gemini -p 'Perform logic audit. Why is this failing?'" <file>
Attempt 3: With Gemini insights
```
**Why:** Second attempt failing means obvious fixes didn't work. Need expert analysis.

### Complexity Trigger: >50 Lines of Code
**Rule:** Complex code = more edge cases = Gemini adds value
```bash
! gemini -p "Perform rigorous logic audit. Look for edge cases, race conditions, off-by-one errors." <file>
```

### Security Trigger: Sensitive Operations
**Rule:** Auth, tokens, permissions, encryption = always get a second opinion
```bash
! gemini -p "Act as security researcher. Check for injection, secret exposure, privilege escalation." <file>
```

### Architecture Trigger: Multiple Valid Approaches Exist
**Rule:** If you see 2+ ways to solve it, get analysis of pros/cons
```bash
! gemini -p "Compare these 2 approaches against best practices. List advantages/disadvantages and recommend." <file>
```

### Integration Trigger: Before Major Refactor/Deployment
**Rule:** Big changes = high risk = need validation
```bash
! gemini -p "Review this refactoring for potential issues. Will this break existing functionality?" <file>
```

---

## ❌ When NOT to Call Gemini (Save Tokens)

1. **Simple code (<10 lines)**
   - Unless it's already failed 2+ times
   - Example: ✅ Don't call Gemini for a 3-line loop

2. **Explicit user instructions given**
   - Follow them directly without debate
   - Example: ❌ Don't ask Gemini if user said "Do it this way"

3. **Recently reviewed similar code**
   - Check decision_log.md first
   - Example: ✅ Don't re-audit similar function if just reviewed

4. **Time-critical tasks**
   - No time for analysis
   - Make best judgment and move on

---

## 📋 Practical Workflow Example

### Scenario: Build a backup verification script

**Step 1: Plan (Claude)**
```
Goal: Verify ZFS backups were successful
Complexity estimate: 40 lines
Security: Medium (checking file permissions)
→ Probably DON'T need Gemini yet
```

**Step 2: Code (Claude)**
```bash
# Write script to verify backups
# Test once - works
# No Gemini call needed yet
```

**Step 3: Handle Failure**
```bash
# User reports: "Script fails on some filenames"
# Try fix #1 - doesn't work
# Try fix #2 - still fails
→ TRIGGER: 2+ failures
→ Call Gemini: "! gemini -p 'Logic audit: Why is filename matching failing?'"
```

**Step 4: Gemini Review**
```
Gemini output (Markdown format):
## Analysis
Examined the filename matching logic...

## Findings
- Issue: Glob pattern doesn't handle spaces correctly
- Issue: Special characters cause expansion issues
- Edge case: Symlinks not followed

## Recommendations
- Use quoted variables: "$file" not $file
- Use find -print0 for null-terminated output
- Add symlink handling option

## Implementation Tips
[Code examples for each fix]
```

**Step 5: Document (Claude)**
```bash
# Add to .ai_context/decision_log.md:
# Date | backup-verify.sh | Filename matching | Use quoted vars + null-terminated output | Fixed
```

**Step 6: Update & Test (Claude)**
```bash
# Apply Gemini's recommendations
# Test again - works
# Deploy
```

---

## 💰 Token Management Strategy

**Budget:** ~10,000 tokens/week for Gemini calls (rough estimate)

**Efficient use:**
- Batch similar audits (review 3 related files in 1 call)
- Don't call for every task (selective, strategic use)
- Keep calls focused (one issue per consultation when possible)
- Check decision_log.md first (don't repeat audits)

**Tracking:**
- Log every Gemini call in `.ai_context/decision_log.md`
- Note date, file, issue, outcome
- Enables spotting repeated patterns (don't call for same issue twice)

---

## 📝 Output Format & Documentation

### Gemini's Markdown Format
```markdown
## Analysis
What was examined, scope of review

## Findings
- Issue 1 (with line numbers if applicable)
- Issue 2
- Pattern noticed: ...

## Recommendations
1. Action 1 (specific, not generic)
2. Action 2
3. Consideration for future work

## Implementation Tips
```bash
# Code example showing how to implement recommendation
```
```

### What Claude Does With Output
1. Read and understand findings
2. Add entry to decision_log.md: `Date | File | Issue | Recommendation | Status`
3. Implement recommendations
4. Test thoroughly before deploying
5. Document outcome in decision_log.md

---

## 🔄 Continuous Improvement

### Weekly Sync
- Review .ai_context/collaboration_history.md
- Identify patterns (same issue appearing multiple times?)
- Adjust strategy if needed
- Archive completed project notes

### Monthly Review
- Check if Gemini calls are valuable (are recommendations being followed?)
- Identify skill gaps (what types of issues keep recurring?)
- Refine decision triggers based on actual results

---

## 🚨 Conflict Resolution

**If Claude and Gemini Disagree:**
1. Document both positions in decision_log.md
2. Claude decides (strategy lead owns final call)
3. If unsure: Ask user for guidance
4. Log the decision and outcome

**Example:**
```
Gemini suggested: Refactor for performance
Claude decision: Keep simple, performance sufficient for now
Reason: Explicit user preference for maintainability over optimization
```

---

## ✅ Checklist Before Each Gemini Call

- [ ] Have I tried simpler approaches first?
- [ ] Is code complex/failed enough to warrant expert analysis?
- [ ] Is this security-sensitive or architectural decision?
- [ ] Is Gemini likely to provide actionable insights?
- [ ] Have I set up .ai_context/current_mission.tmp?
- [ ] Is the file path correct?
- [ ] Am I tracking this in decision_log.md?

If ≥5 checkmarks, proceed with Gemini call.
If <5 checkmarks, handle it yourself.

---

## 📚 Reference
- `CLAUDE.md` - Detailed collaboration protocol (sections 6-10)
- `ORGANIZATION.md` - Folder structure guide
- `.ai_context/decision_log.md` - Call history for this project
- `.ai_context/collaboration_history.md` - Global patterns & lessons
