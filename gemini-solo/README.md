# Gemini Solo: Gemini Analysis Archive

**Purpose:** Store Gemini analysis reports and audit output (not active code)

---

## 📂 Organization

### **logic-audits/**
Stored reports from Gemini logic audits
- File: `[date]-[filename]-logic-audit.md`
- Content: Analysis of code logic, edge cases, correctness
- Example: `2026-01-01-backup-verify-logic-audit.md`

### **security-reviews/**
Stored reports from Gemini security reviews
- File: `[date]-[filename]-security-review.md`
- Content: Security vulnerability analysis, recommendations
- Example: `2026-01-01-auth-handler-security-review.md`

### **architecture-analysis/**
Stored architectural evaluations and design decisions
- File: `[date]-[project-name]-architecture.md`
- Content: Design analysis, best practices comparison, recommendations
- Example: `2026-01-01-backup-system-architecture.md`

---

## 📋 Report Template

Each report should follow this structure:

```markdown
# Gemini [Type] Report: [File/Project Name]

**Date:** 2026-01-01
**Analyzed By:** Gemini
**Analyzed By Claude:** For [specific concern/requirement]
**File(s) Analyzed:** [path/to/file.sh]
**Status:** [Implemented / Pending / Rejected]

## Analysis
Brief summary of what was examined and scope.

## Findings
- **Finding 1:** Description with line number/context
- **Finding 2:** Description with impact
- **Pattern Noticed:** If applicable, recurring issues

## Recommendations
1. **Recommendation 1:** Specific action with rationale
2. **Recommendation 2:** Alternative approach
3. **Best Practice Note:** If applicable

## Implementation Tips
```bash
# Code example showing recommended implementation
```

## Follow-Up Actions
- [ ] Action 1 (assigned to Claude if applicable)
- [ ] Action 2

## Notes
Any context or caveats about the analysis.
```

---

## 📊 How Claude Uses These Reports

### When Creating Report
1. Gemini analysis is stored here as reference
2. Claude implements recommendations in actual code
3. File tracks status of follow-up actions

### When Reviewing History
1. Claude checks here to avoid duplicate analysis
2. Example: "We already audited similar code in `logic-audits/` - check there first"
3. Helps identify patterns across projects

### Knowledge Transfer
Reports become documentation:
- New collaborators understand past decisions
- Patterns become visible over time
- Lessons learned are preserved

---

## 🔄 Report Lifecycle

```
1. Claude calls Gemini for analysis
   ↓
2. Gemini produces Markdown output
   ↓
3. Claude saves report here with standardized naming
   ↓
4. Claude updates status (Implemented/Pending/Rejected)
   ↓
5. Report becomes reference for future similar code
```

---

## 🏷️ Naming Convention

```
[date]-[filename]-[type]-report.md

Examples:
  2026-01-01-backup-verify-logic-audit-report.md
  2026-01-02-auth-handler-security-review-report.md
  2026-01-03-transfer-system-architecture-report.md
```

---

## 📈 Using Archives for Pattern Recognition

Over time, this folder shows:
- **Common vulnerabilities** → Prevention strategies
- **Recurring logic issues** → Better initial code practices
- **Design patterns** → Reusable solutions
- **Lessons learned** → Faster problem-solving

**Monthly Review:** Check collaboration_history.md for patterns across all reports

---

## 🚫 What Does NOT Go Here

- ❌ Active code files (keep in ai-projects/ or claude-solo/)
- ❌ Work-in-progress analysis (finalize first)
- ❌ Raw Gemini terminal output (convert to proper report format)

---

## 🔗 Related Documentation
- `STRATEGIC-FRAMEWORK.md` - When to consult Gemini
- `.ai_context/collaboration_history.md` - Track patterns over time
- `ai-projects/` - Where recommendations are implemented

---

**Last Updated:** 2026-01-01
