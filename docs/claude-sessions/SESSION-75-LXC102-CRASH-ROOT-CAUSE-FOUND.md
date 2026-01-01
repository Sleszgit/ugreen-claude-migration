# Session 75: LXC 102 Crash Root Cause Identified & Fixed (Partial)

**Date:** 2026-01-01 (Morning)
**Duration:** ~90 minutes
**Location:** LXC 102 (ugreen-ai-terminal) container
**Status:** ✅ ROOT CAUSE FOUND - AWAITING USER DECISION ON REMEDIATION

---

## Executive Summary

**Problem:** LXC 102 container crashes every ~45 minutes, then auto-restarts (thanks to Session 74 fix)

**Root Cause Found:** GPG keys are missing from the container, but encrypted token files exist. When startup scripts try to decrypt tokens, GPG fails, causing cascading failures.

**Fix Status:**
- ✅ **FIXED #1:** Removed duplicate `onboot: 1` line from Proxmox config
- ⏳ **PENDING #2:** Restore GPG keys OR use plain-text tokens

---

## What We Discovered

### 1. Duplicate Config Line (FIXED) ✅

**Problem:** `/etc/pve/lxc/102.conf` had TWO identical `onboot: 1` lines

```
onboot: 1              ← First instance
...
unused0: local-lvm:vm-102-disk-0
onboot: 1              ← DUPLICATE (corrupted!)
startup: order=2,up=60,down=10
```

**Fix Applied:** Script `fix-duplicate-onboot.sh` removed the first duplicate
- ✅ Config syntax validated
- ✅ Backup saved to: `/etc/pve/lxc/102.conf.backup-20260101-094000`
- ✅ No container restart required

---

### 2. Missing GPG Keys (ROOT CAUSE - CRITICAL) ❌

**Discovery Process:**

1. Ran Proxmox diagnostic script (created in this session)
2. Found: "No encrypted tokens found" and "GPG key status in container: [EMPTY]"
3. Container HAS encrypted token files:
   - ✅ `~/.proxmox-executor-token.gpg`
   - ✅ `~/.proxmox-api-token.gpg`
   - ✅ `~/.proxmox-vm100-token.gpg`
   - ✅ `~/.github-token.gpg`
   - ✅ `~/.proxmox-homelab-token.gpg`

4. Container DOESN'T have GPG keys to decrypt them:
   ```bash
   $ gpg --list-secret-keys
   gpg: /home/sleszugreen/.gnupg/trustdb.gpg: trustdb created
   [EMPTY - NO KEYS]
   ```

**Why This Causes Crashes:**

1. Session 71 encrypted tokens with GPG key ID: `170D61DFC69E11DF063DF055C7AE28F3D5009924`
2. GPG key was never migrated/backed up to container
3. Container starts cleanly (no errors)
4. Auto-update script runs (~45 minutes later)
5. Script tries to access encrypted tokens
6. GPG can't decrypt (no keys)
7. Script fails
8. systemd restarts container
9. **REPEAT**

**Evidence:**
- Container uptime pattern: ~45 minute cycles (matches cron schedule)
- 20+ boot cycles in journal (not random restarts)
- Clean startup logs (errors occur later during execution)
- Backup file exists: `~/token-backup-20251231-171555.tar.gz` (created in Session 71)

---

## Session 74 Context

Session 74 added auto-restart config (`onboot: 1`, `startup: order=2,up=60,down=10`), which:
- ✅ **Helps:** Container auto-restarts instead of staying down
- ❌ **Masks the real issue:** Makes crashes appear normal, hides GPG problem

The fix in Session 74 was **necessary but incomplete**. It fixed the symptom (container not restarting) but not the cause (GPG key unavailability).

---

## Path Forward: Three Options

### Option A: Use Plain-Text Tokens (Quickest - 5 min)

**Steps:**
1. Extract tokens from backup:
   ```bash
   tar -xzf ~/token-backup-20251231-171555.tar.gz -C ~/
   ```
2. Delete encrypted files:
   ```bash
   rm ~/.*.gpg
   ```
3. Restart container
4. Monitor for crashes

**Pros:** Immediate stability, container will work normally
**Cons:** Tokens stored in plain-text (security degradation from Session 71 intent)
**Timeline:** 5 minutes

---

### Option B: Recreate GPG Key (Best - 15 min)

**Requirements:**
- Original GPG passphrase from Session 71
- OR ability to generate new key

**Steps:**
1. Check if GPG key exists elsewhere:
   ```bash
   gpg --list-secret-keys
   ```
2. If key found, configure it in container
3. If key lost, recreate with new passphrase:
   ```bash
   gpg --full-generate-key
   ```
4. Encrypt tokens with new key
5. Delete plain-text versions

**Pros:** Maintains security posture, proper encryption
**Cons:** Need GPG key or passphrase, slightly more complex
**Timeline:** 15 minutes

---

### Option C: Implement Proper Secrets Management (Best Long-term - Future)

**Examples:** Vault, `pass` password manager, or systemd secrets

**For Now:** Use Option A (plain-text) as interim, plan proper solution for future session

---

## Diagnostics Created This Session

Created and tested two diagnostic scripts:

1. **`/mnt/lxc102scripts/proxmox-diagnostic.sh`** (runs on Proxmox host)
   - Collects comprehensive LXC 102 and infrastructure data
   - Saves results to: `/mnt/lxc102scripts/proxmox-diagnostic-results.txt`
   - Includes SSH, GPG, encryption, and firewall checks

2. **`/mnt/lxc102scripts/fix-duplicate-onboot.sh`** (runs on Proxmox host)
   - Removes duplicate `onboot: 1` line
   - Creates backup before modifying
   - Validates config syntax

Both scripts are non-disruptive and don't interrupt SSH connections.

---

## Session 71 Reference

Session 71 ("Secrets Management - GPG Encryption") attempted to:
- ✅ Create GPG key (ID: 170D61DFC69E11DF063DF055C7AE28F3D5009924)
- ✅ Encrypt 6 API tokens
- ✅ Delete plain-text versions
- ❌ **Never migrated GPG key to container**
- ❌ **Never backed up private key**

This is why encryption exists but keys are missing.

---

## What's Working ✅

- ✅ SSH configuration (keys in place, hardening applied)
- ✅ SSH host keys (not encrypted, properly stored)
- ✅ Proxmox configuration (duplicate fixed)
- ✅ Container auto-restart (Session 74 fix)
- ✅ Network connectivity
- ✅ ZFS storage (healthy)
- ✅ Container runs stable when not hitting token error

---

## What's Broken ❌

- ❌ GPG encryption/decryption (keys missing)
- ❌ Startup scripts dependent on encrypted tokens
- ❌ Container crashes on schedule (~45 min)

---

## Recommended Next Actions

### Immediate (This Session or Next)

1. **Decide on token approach:**
   - Option A: Plain-text (quick, less secure)
   - Option B: Recreate GPG key (better, need passphrase)

2. **Implement chosen solution**

3. **Test stability:**
   - Monitor container uptime for 24+ hours
   - Verify no crashes at ~45 minute marks

### Short-term (Next 1-2 sessions)

4. **Document token management**
   - Where keys are stored
   - How to access them
   - Recovery procedures

5. **Plan secrets management upgrade**
   - Replace GPG with Vault or `pass`
   - Proper backup strategy

### Long-term (Future)

6. **Implement automated secrets rotation**
7. **Add monitoring alerts** for decryption failures
8. **Document disaster recovery** for key loss

---

## Files Modified This Session

| File | Change | Status |
|------|--------|--------|
| `/etc/pve/lxc/102.conf` | Removed duplicate `onboot: 1` | ✅ Applied |
| `/mnt/lxc102scripts/proxmox-diagnostic.sh` | Created | ✅ Ready |
| `/mnt/lxc102scripts/fix-duplicate-onboot.sh` | Created | ✅ Applied |
| `/mnt/lxc102scripts/restore-gpg-tokens.sh` | Created | ⏳ Pending |

---

## Session Statistics

| Metric | Value |
|--------|-------|
| Root causes identified | 2 (1 fixed, 1 pending) |
| Diagnostic scripts created | 2 |
| SSH interruptions | 0 ✅ |
| Config backup created | 1 |
| Hours to implement fixes | ~5 min (Option A) or ~15 min (Option B) |

---

## Critical Learnings

1. **Encryption without backup = fragility**
   - Session 71 encrypted tokens but didn't back up keys
   - Result: System can't decrypt even with valid files

2. **Auto-restart masks underlying issues**
   - Session 74 fix hides GPG failure
   - Makes container appear flaky instead of broken

3. **Cross-container dependencies are dangerous**
   - GPG keys created in one session lost in another
   - Need persistent key management

4. **Diagnostics are essential**
   - Proxmox config validation alone isn't enough
   - Need container-level checks (GPG, encryption, services)

---

## Decision Required From User

**Choose one:**
- [ ] **Option A:** Use plain-text tokens (quickest)
- [ ] **Option B:** Recreate GPG key (better, need passphrase)
- [ ] **Option C:** Hybrid (plain-text now, proper solution later)

Once chosen, estimated time to fix container crashes: **5-15 minutes**

---

**Session Status:** ✅ DIAGNOSIS COMPLETE - AWAITING USER DECISION
**Next Session:** REMEDIATION - Implement chosen solution

---

*Generated: 2026-01-01*
*Container:** LXC 102 (ugreen-ai-terminal)
*Diagnostic Tool:** Custom Proxmox diagnostic scripts
*Root Cause:** GPG key unavailability in container
