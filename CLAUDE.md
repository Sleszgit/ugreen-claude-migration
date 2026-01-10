# Claude Code Project Guidelines

**Last Updated:** January 10, 2026
**Established By:** Session 108 - Docker Deployment & Workflow Refinement

---

## CRITICAL: No Heredoc/EOF Commands Rule

**PRINCIPLE: NEVER use heredoc or EOF patterns (`cat <<EOF ... EOF`, `sudo tee <<EOF ... EOF`) to give commands.**

### Alternatives (in priority order):

1. **Use the Write tool** - For creating files locally, then deploy via SSH
2. **Use echo with quoting** - For simple multi-line content via shell
3. **Ask you to paste content** - If alternatives don't work
4. **STOP and get approval** - If heredoc is the ONLY option, state it explicitly and wait

### When I Cannot Find an Alternative:
- I stop immediately
- I explain why alternatives don't work
- I explicitly state: "I need to use a heredoc command. Do you want me to proceed?"
- I wait for your approval

---

# GEMINI GUIDELINES: Bash Script Analysis & Recommendations

**Last Updated:** January 2, 2026
**Reference:** Post-mortem from Filmy920 transfer script debugging

---

## CRITICAL: Mandatory Bash Script Guidelines

When analyzing, auditing, or recommending changes to bash scripts, you MUST enforce these guidelines derived from real-world debugging failures:

### Guideline #1: Unbreakable Script Header
**ALWAYS recommend:**
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

- `E`: Traps inherited by functions/subshells
- `e`: Exit on ANY error
- `u`: Unset variables cause exit
- `o pipefail`: Pipeline fails if any command fails

**Flag ANY script lacking this.** It's the foundation for safe bash.

---

### Guideline #2: ALWAYS Require an ERR Trap
**ALWAYS recommend:**
```bash
trap 'echo "ERROR on line $LINENO, exit code $?"' ERR
```

**Why:** Without this, scripts can fail silently with zero console feedback (wasted 3+ hours debugging this exact issue).

**Flag ANY script without ERR trap.** It's non-negotiable for production code.

---

### Guideline #3: NEVER Allow Global Output Redirection
**WRONG (flag this):**
```bash
exec > >(tee -a "$LOG_FILE")  # ALL output redirected globally
```

**RIGHT (recommend this):**
```bash
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') | $*" | tee -a "$LOG_FILE"
}

log "Starting..."
log "Processing..."
```

**Why:** Global redirection = silent failures if log path becomes inaccessible. Explicit log() function ensures visibility.

**This is the single biggest cause of the 3-hour debugging session we just completed.**

---

### Guideline #4: Require Upfront Validation
**ALWAYS recommend:**
```bash
# FIRST THING - validate directory and permissions
LOG_DIR="/var/log/my_script"
mkdir -p "$LOG_DIR" || { echo "FATAL: Cannot create $LOG_DIR"; exit 1; }
touch "$LOG_FILE" || { echo "FATAL: Cannot write $LOG_FILE"; exit 1; }

# ONLY THEN proceed with script logic
```

**Flag ANY script that:**
- Tries to write logs/output without validating the path first
- Assumes directories exist without creating them
- Has no upfront permission checks

**Why:** Fail-fast at line 20 with a clear message, not hidden at line 200 with a cryptic error.

---

### Guideline #5: Quote ALL Variable Expansions
**Flag this pattern:**
```bash
# WRONG
rsync $SOURCE_PATH $DEST_PATH
rm -rf $SOME_DIR
```

**Recommend this:**
```bash
# RIGHT
rsync "$SOURCE_PATH" "$DEST_PATH"
rm -rf "$SOME_DIR"
```

**Why:** Unquoted variables undergo word splitting and glob expansion, causing:
- Arguments to be mangled (e.g., `"my file.txt"` becomes two arguments)
- Glob expansions (e.g., `$VAR="*"` deletes everything in current directory)

---

### Guideline #6: Explicit Logging in Loop Bodies
**Flag loops with zero internal logging:**
```bash
# WRONG - no visibility
for folder in "${FOLDERS[@]}"; do
    rsync ...
done

# RIGHT - explicit logging
for folder in "${FOLDERS[@]}"; do
    log "Processing folder: $folder"
    log "  Source: $SOURCE_PATH"
    log "  Dest: $DEST_PATH"
    rsync ...
done
```

**Why:** When loops fail, you need to know which iteration and what values were used. Zero visibility = 3 hour debugging session.

---

### Guideline #7: Avoid `set -x` on Complex Scripts
**Flag this pattern:**
```bash
# WRONG - set -x on complex operations
set -x
for folder in "${ARRAY[@]}"; do
    SOURCE_PATH="$NAS_MOUNT/$folder"
    rsync ...
done
set +x
```

**Recommend this instead:**
```bash
# RIGHT - explicit logging
for folder in "${ARRAY[@]}"; do
    SOURCE_PATH="$NAS_MOUNT/$folder"
    log "DEBUG: Processing $folder, SOURCE_PATH=$SOURCE_PATH"
    rsync ...
done
```

**Why:** `set -x` output gets redirected to the same place as regular output, can interfere with redirection expectations, and obscures actual error messages.

---

## When Reviewing Bash Scripts

### Checklist Before Approving Any Script

- [ ] Has `set -Eeuo pipefail`?
- [ ] Has `trap 'error_handler $? $LINENO' ERR`?
- [ ] Uses log() function instead of global redirection?
- [ ] Validates directories/permissions upfront?
- [ ] Quotes ALL variable expansions?
- [ ] Has logging in all loop bodies?
- [ ] Avoids `set -x` for debugging?
- [ ] Has `mkdir -p` for all destination paths?
- [ ] Handles destination directory creation?
- [ ] No hardcoded /root paths (use /tmp or configurable)?

**If ANY checkbox is empty, recommend the fix.**

---

## Historical Context: Why These Rules Exist

**Filmy920 Transfer Script Debugging Session:**
- Duration: 3+ hours
- Test iterations: 12+
- Real bugs: 2
- Root causes identified: Silent failures from lack of visibility + cascading errors
- Lessons learned: Output redirection kills visibility; explicit logging saves hours

**The script's actual bugs were:**
1. Log directory not writable (permissions issue)
2. Destination directories not created (missing mkdir -p)

**But diagnosis took 12+ iterations because:**
- Silent failures with output redirected to unavailable files
- No visibility into loop execution
- Each failure masked the next one (cascading)
- Red herrings (CRLF, set -x, variable failures) wasted iterations

**Takeaway:** These 7 guidelines prevent this exact scenario from happening again.

---

## Reference: Full Audit Report

For the complete post-mortem analysis, see:
`/home/sleszugreen/.ai_context/AUDIT_REPORT_FINAL.md`

---

## Your Responsibility as Gemini

When analyzing bash scripts:

1. **Check against these guidelines first** - Flag any violations
2. **Recommend the template** - For any script lacking structure
3. **Enforce visibility** - Explicit logging over set -x or global redirection
4. **Demand upfront validation** - No silent failures on directory/permission issues
5. **Quote everything** - It's the right thing to do

These aren't suggestions. They're lessons earned through painful debugging sessions. Apply them consistently.
