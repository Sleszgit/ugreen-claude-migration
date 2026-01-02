# FILMY920 TRANSFER SCRIPT: POST-MORTEM AUDIT REPORT

**Date:** January 2, 2026  
**Duration:** ~3 hours of debugging  
**Iterations:** 12+ test runs  
**Final Result:** ✅ Script now working successfully

---

## Executive Summary

The debugging session suffered from **cascading silent failures** that masked two simple issues behind mountains of red herrings. The script had no visibility into failures, making diagnosis extremely difficult. Only 2 real bugs existed, but 12+ iterations were required because each error was invisible.

---

## ROOT CAUSE ANALYSIS

### Why "Tens of Failures" From Only 2 Real Issues?

**The Core Problem: Silent Failures + Output Redirection**

When a bash script with `set -e` tries to redirect output to a non-existent directory, the redirection fails, the script exits, but no error is printed anywhere. The script simply vanishes.

```
Script tries: echo "message" >> /nonexistent_dir/log.txt
Result: mkdir not done, directory doesn't exist
Outcome: Redirection fails silently, set -e exits, no console output
Diagnosis: Script seems to work (no errors printed) but produces no results
```

### Cascading Failure Pattern

1. **FAILURE #1**: Log directory permission issue
   - Caused: Script exit before loop execution
   - Symptom: STEP 6 started, then immediate cleanup
   - Diagnosis took: Multiple iterations because output was redirected to unavailable file

2. **FAILURE #2**: For loop never ran (because script exited earlier)
   - Caused: Users couldn't debug the loop itself
   - Symptom: No loop iteration messages, appeared like loop didn't exist
   - Each attempted fix: "Nope, still no output"

3. **FAILURE #3**: When loop finally ran (after log dir fix), new issue: destination directory missing
   - Caused: Script never created /WD10TB/Filmy920/2022
   - Would have been discovered immediately if debugging visibility existed
   - Hidden by: Same silent failure pattern

### Why Diagnosis Was So Difficult

| Problem | Traditional Approach | What We Did | Result |
|---------|---------------------|------------|--------|
| Silent failures | Try to see error message | None visible - output redirected to unavailable file | Wasted 4 iterations |
| set -x interference | Add command tracing | Made it worse, masked real issue | Wasted 2 iterations |
| Red herring: CRLF | Fix file line endings | Didn't help because wasn't the issue | Wasted 1 iteration |
| Multiple layers of error | Fix one, discover next | Log dir → loop doesn't run → mkdir missing | Wasted 3+ iterations |
| Lack of intermediate logging | Hope the script works | Added aggressive debug logging everywhere | Finally revealed truth |

---

## CONCRETE GUIDELINES FOR FUTURE SCRIPTS

### Guideline #1: Unbreakable Script Header
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

**Why:** This is the golden standard for bash scripts.
- `E`: Traps (ERR trap) inherited by functions and subshells
- `e`: Exit on any error
- `u`: Unset variables are errors
- `o pipefail`: Pipeline fails if any command fails

**Prevents:** Silent failures from unset variables, pipeline failures being masked, errors in functions not being caught

---

### Guideline #2: Always Use an ERR Trap
```bash
trap 'echo "ERROR on line $LINENO, exit code $?"' ERR
```

**Why:** The ERR trap GUARANTEES you'll see where the script failed, even if output is redirected.

**Prevents:** Scripts that "just silently exit" with no explanation

---

### Guideline #3: Never Use Global Output Redirection
**WRONG:**
```bash
exec > >(tee -a "$LOG_FILE")  # Redirects ALL output
# ... rest of script ...
```

**RIGHT:**
```bash
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') | $*" | tee -a "$LOG_FILE"
}

log "Starting..."
log "Processing..."
```

**Why:** With global redirection, if the log file becomes inaccessible, the script exits with zero console feedback. Explicit `log()` function ensures you see messages even if logging fails.

**Prevents:** The exact scenario we spent 3 hours debugging

---

### Guideline #4: Validate Directories and Permissions Upfront
```bash
# DO THIS FIRST
LOG_DIR="/var/log/my_script"
mkdir -p "$LOG_DIR" || { echo "ERROR: Cannot create $LOG_DIR"; exit 1; }
touch "$LOG_FILE" || { echo "ERROR: Cannot write to $LOG_FILE"; exit 1; }

# ONLY THEN proceed with script logic
```

**Why:** Fail-fast. Better to die on line 20 with a clear message than on line 200 with a cryptic error.

**Prevents:** Discovering directory problems 3 hours into a debug session

---

### Guideline #5: Quote All Variable Expansions
```bash
# WRONG
rsync $SOURCE_PATH $DEST_PATH

# RIGHT
rsync "$SOURCE_PATH" "$DEST_PATH"
```

**Why:** Unquoted variables undergo word splitting and glob expansion.
- `$VAR="my file.txt"` → expands to `my file.txt` (two arguments)
- `$VAR="*"` → expands to all files in current directory

**Prevents:** Arguments being mangled, files being deleted accidentally

---

### Guideline #6: Explicit Logging in Loop Bodies
```bash
for folder in "${FOLDERS[@]}"; do
    log "Processing folder: $folder"
    log "  Source: $SOURCE"
    log "  Dest: $DEST"
    
    # Then run the actual command
    rsync ...
done
```

**Why:** When a loop fails mysteriously, the logging tells you which iteration and which variables.

**Prevents:** Entire loop sections having zero visibility

---

### Guideline #7: Don't Use set -x for Debugging Complex Scripts
```bash
# AVOID THIS
set -x
for folder in "${ARRAY[@]}"; do
    ...
done
set +x

# DO THIS INSTEAD
for folder in "${ARRAY[@]}"; do
    log "DEBUG: Processing $folder with value=$value"
    # Run command
done
```

**Why:** `set -x` output gets redirected to the same place as regular output, can interfere with redirection expectations, and makes output confusing.

**Prevents:** `set -x` hiding the actual error message you need to see

---

## DEBUG STRATEGY: 10x Faster Diagnosis

When a bash script fails mysteriously:

1. **Remove ALL Output Redirections Immediately**
   ```bash
   # Comment out these lines:
   # exec > >(tee "$LOG_FILE")
   # ... and any > or | tee operations
   ```
   **Reason:** Forces all errors to your terminal where you can see them

2. **Add a Logging Function (Not set -x)**
   ```bash
   log() { echo "[DEBUG] $*"; }
   log "Starting..."
   log "Variable X = $X"
   ```
   **Reason:** Explicit, controllable, can be left in production code

3. **Run with bash -x if Absolutely Necessary**
   ```bash
   bash -x ./script.sh 2>&1 | tee debug.log
   ```
   **Reason:** Shows every command as it executes; last command before exit is the culprit

4. **Check Exit Code Immediately**
   ```bash
   ./script.sh
   echo "Exit code: $?"
   ```
   **Reason:** Different exit codes mean different things (126=not executable, 127=not found, etc.)

5. **Isolate the Problem**
   - Run just the failing function in isolation
   - Create a minimal test case
   - Add logging before and after each major operation

---

## SCRIPT TEMPLATE FOR FUTURE USE

```bash
#!/usr/bin/env bash
#
# Robust Bash Script Template
#

set -Eeuo pipefail

LOG_FILE="${LOG_FILE:-/tmp/$(basename "$0").log}"
SCRIPT_NAME=$(basename "$0")

# === ERROR HANDLING ===
error_handler() {
  local exit_code="$1"
  local line_no="$2"
  log "ERROR: Failed on line $line_no with exit code $exit_code"
}

cleanup() {
  log "Script finished"
}

trap 'error_handler $? $LINENO' ERR
trap 'cleanup' EXIT

# === LOGGING ===
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') | $SCRIPT_NAME | $*" | tee -a "$LOG_FILE" >&1
}

# === MAIN ===
main() {
  # 1. Validate upfront
  log "Validating environment..."
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE" || { echo "FATAL: Cannot write to $LOG_FILE"; exit 1; }
  
  # 2. Check dependencies
  command -v required_cmd >/dev/null || { log "FATAL: required_cmd not found"; exit 1; }
  
  # 3. Log every major step
  log "Starting main task..."
  
  # 4. Use explicit logging in loops
  for item in "${ITEMS[@]}"; do
    log "  Processing: $item"
    # Run command...
  done
  
  log "Completed successfully"
}

main "$@"
```

---

## KEY TAKEAWAYS

1. **Output redirection kills visibility** → Use a log function instead of global redirection
2. **set -e + silent failures = 3-hour debug sessions** → Use ERR trap for guaranteed error messages
3. **set -x helps, but explicit logging helps more** → Add log() function calls to every critical section
4. **Fail early and loudly** → Validate directories, permissions, and dependencies at the start
5. **Cascading failures hide real bugs** → Each failure can mask the next one; add logging between every major operation

---

## LESSONS FROM THIS SESSION

| What Went Wrong | What To Do Next Time |
|-----------------|---------------------|
| Silent failure on line 1 | Validate upfront with explicit error messages |
| No visibility into loop | Add `log` statement at start of every loop iteration |
| Debugging with set -x | Use explicit `log` calls instead |
| Multiple potential issues | Add logging to narrow down which one actually failed |
| 12 iterations to find 2 bugs | Aggressive upfront logging would have revealed them in iteration 3 |

---

**Recommendation:** Use the script template above for all future transfer/backup scripts. The upfront validation and logging will save hours of debugging.

