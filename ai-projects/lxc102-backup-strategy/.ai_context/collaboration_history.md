# AI Agent Collaboration History (Global)

**Purpose:** Track patterns, token usage, and lessons learned from Claude + Gemini collaboration across all projects.

**Last Updated:** 2026-01-01

---

## 📊 Gemini Consultation Stats

| Metric | Count | Notes |
|--------|-------|-------|
| Total consultations | 0 | Track all calls |
| Security audits | 0 | Issues found: 0 |
| Logic audits | 0 | Bugs prevented: 0 |
| Architecture reviews | 0 | Improvements suggested: 0 |
| Failed calls | 0 | Path/timeout errors |
| Avg response length | 0 words | Efficiency metric |

---

## 🔍 Patterns Observed

### Security Findings
- **Type:** [To be populated]
- **Frequency:** [X occurrences]
- **Root cause:** [Common source]
- **Prevention:** [Best practice]

*Example pattern (remove this line later):*
- **Type:** Token exposure in logs
- **Frequency:** 2 times
- **Root cause:** Debug output not sanitized
- **Prevention:** Always strip sensitive data from logs before output

---

## 💡 Lessons Learned

1. **Lesson Title**
   - What happened: [Description]
   - Why it matters: [Impact]
   - How to prevent: [Action]

*Example (remove this line later):*
1. **Batch Similar Reviews**
   - What happened: Called Gemini 3 times for similar security checks
   - Why it matters: Wasted tokens on repetitive analysis
   - How to prevent: Group similar files for one comprehensive review

---

## 🎯 Gemini Call Decision Log

This log answers: "When should I consult Gemini?"

### Previous Calls
*Format: Date | Issue Type | Files | Outcome | Time to Resolution | Tokens Estimate*

---

## 🚨 Failure Cases (When NOT to Call Gemini)

- **Attempted:** [Description]
- **Why it failed:** [Error message]
- **Better approach:** [What to do instead]

*Example (remove this line later):*
- **Attempted:** Gemini review of 500-line script without simplification
- **Why it failed:** Response truncated, analysis incomplete
- **Better approach:** Split into smaller logical sections, review one at a time

---

## 📈 Token Budget Management

**Available Plans:**
- Claude: Paid plan (not infinite)
- Gemini: Paid plan (not infinite)

**Tracking:**
- Estimated tokens per consultation: ~2000-5000 words
- Frequency goal: 1-3 Gemini calls per project
- Batch reviews to avoid repetition

**Current Status:**
- Month to date: [Track manually]
- Calls this month: 0
- Estimated tokens used: 0

---

## 🔄 Project-Specific Notes

### [Project Name]
- **Consultations:** 0
- **Key findings:** None yet
- **Next review trigger:** [When complexity increases, failed attempts, etc.]

---

## 📋 Template for New Project

When starting a new collaborative project:

1. Create `./.ai_context/` folder in project root
2. Copy this template as starting point
3. Add project name under "Project-Specific Notes"
4. Update global stats as work progresses
5. Archive entry when project completes

---

**Sync Strategy:** This file updates when:
- ✅ Gemini is called (add to decision log)
- ✅ New pattern observed (add to patterns section)
- ✅ Lesson learned (document immediately)
- ✅ Project completes (archive findings)
