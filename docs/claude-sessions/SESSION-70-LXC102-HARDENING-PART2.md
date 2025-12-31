# Session 70: LXC 102 Hardening - Part 2 (File Permissions & SSH)
**Date:** 31 Dec 2025
**Duration:** ~45 minutes
**Location:** LXC 102 (ugreen-ai-terminal)
**Status:** ✅ COMPLETE - All HIGH PRIORITY tasks finished

---

## Objective
Continue LXC 102 security hardening from Session 69. Fix file permissions, harden SSH configuration, and install firewall protection.

---

## What Was Accomplished

### 1. ✅ File Permission Fixes (5 mins)
**Rationale:** Prepare for multi-AI agent architecture where Claude Code and Gemini both run as `sleszugreen` and share access to scripts/configs.

| File/Directory | Before | After | Reason |
|---|---|---|---|
| `.bashrc` | 644 | 600 | Restrict shell config to owner only |
| `.bash_history` | 600 | ✅ Already correct | Good - command history protected |
| `.gemini/` | 775 | 755 | Allow read/execute for other processes, owner-only write |
| `~/scripts/` | 755 | ✅ Already correct | Proper directory permissions |
| Script subdirs | 775 | 755 | Remove group write permission |
| `*.sh` files | Mixed | 755 | All executable scripts set to 755 |
| Data files | Mixed | 644 | Non-executable files set to 644 |

**Verification:**
```bash
ls -la ~/ | grep -E "bashrc|bash_history|\.gemini|scripts"
# Results: All showing correct permissions
```

---

### 2. ✅ SSH Configuration Hardening (15 mins)
**Changes applied to `/etc/ssh/sshd_config`:**

| Setting | Old Value | New Value | Purpose |
|---------|-----------|-----------|---------|
| X11Forwarding | yes | no | Disable X11 forwarding (exploit vector) |
| MaxAuthTries | 6 | 3 | Limit failed auth attempts |
| MaxSessions | 10 | 5 | Limit concurrent sessions per user |
| Compression | (disabled) | delayed | Enable post-auth compression |
| ClientAliveInterval | 0 | 1200 (20 mins) | Auto-close idle SSH sessions |
| ClientAliveCountMax | 3 | 2 | Close after 2 missed keepalives |

**Verification:**
```bash
grep -E "^X11Forwarding|^MaxAuthTries|^MaxSessions|^Compression|^ClientAlive" /etc/sshd_config
# All settings confirmed with correct values

sudo sshd -T
# Syntax validation passed ✅
```

**Security Impact:**
- Reduced SSH attack surface (no X11 exploitation)
- Better protection against brute force (MaxAuthTries 3)
- Idle session management (20-minute timeout)
- Connection liveness detection (keepalives)

**User Impact:**
- ✅ Zero impact on key-based authentication (your normal usage)
- ✅ Idle SSH sessions auto-close after ~20 minutes (acceptable)
- ✅ X11 forwarding disabled (not used in LXC terminal)

---

## Files Modified

| File | Changes | Type |
|------|---------|------|
| `/etc/ssh/sshd_config` | 6 settings updated for hardening | Security config |
| `.bashrc` | Permission changed 644 → 600 | File permissions |
| `.gemini/` | Permission changed 775 → 755 | Directory permissions |
| `~/scripts/` subdirs | All changed to 755 | Directory permissions |
| Script files | `.sh` files set to 755, others to 644 | File permissions |

**Backups created:**
- `/etc/ssh/sshd_config.backup.*` - SSH config backup before hardening

---

### 3. ✅ UFW Firewall Installation & Configuration (15 mins)
**Changes applied:**

| Setting | Value | Purpose |
|---------|-------|---------|
| UFW Status | Enabled | Firewall active on boot |
| Default Incoming | Deny | Block all unsolicited inbound |
| Default Outgoing | Allow | Allow all outbound connections |
| SSH Port 22/tcp | Allow | Explicit exception for SSH |

**Verification:**
```bash
# UFW enabled in config
ENABLED=yes  ✅

# SSH listening on port 22
LISTEN 0.0.0.0:22     ✅
LISTEN [::]:22        ✅

# SSH accessibility tested
✅ Current SSH connection remains active
✅ New SSH connection from MobaXterm successful
✅ Port 22 reachable locally and remotely
```

**Security Impact:**
- Default deny-by-default firewall policy active
- Only explicitly allowed traffic permitted
- SSH preserved for remote administration
- All outbound allowed (updates, API calls, etc.)

**User Impact:**
- ✅ Zero impact - remote SSH works perfectly
- ✅ Verified with MobaXterm new connection
- ✅ No disruption to normal operations

---

## Architecture Notes

### Multi-AI Agent Design
Both Claude Code and Gemini are installed and run as `sleszugreen` user:
- Permissions set to allow both to read/write shared resources
- `.gemini/`: 755 allows Gemini to read API config while owner retains write control
- `~/scripts/`: 755 allows Gemini to read scripts Claude Code creates
- Future AI agents (if run as same user) will have seamless access

### SSH Access Verification
Confirmed remote SSH access from desktop to LXC 102 will continue working:
- ✅ SSH server on port 22 (default)
- ✅ No Proxmox host firewall rules blocking access
- ✅ Same network (192.168.40.x)
- ✅ Ready for UFW setup (which will explicitly allow port 22)

---

## Security Status After Session 70

| Category | Before | After | Status |
|----------|--------|-------|--------|
| File Permissions | Partially incorrect | ✅ All fixed | Improved |
| SSH Attack Surface | High (X11Forwarding enabled) | ✅ Reduced | Improved |
| Session Management | None | ✅ 20-min timeout | New |
| Brute Force Protection | Basic | ✅ MaxAuthTries 3 | Improved |

**Overall Security Grade:** A (from Session 69)

---

## Remaining Tasks - MEDIUM & LOW Priority

### MEDIUM PRIORITY (1-2 hours each)

**1. Secrets Management (pass) - RECOMMENDED NEXT**
- Encrypt 6 API tokens currently stored as plain files
- Prevent exposure if shell access is compromised
- Use `pass` tool (GPG-based, simple for single user)
- Effort: 1-2 hours
- Risk reduction: HIGH (tokens are critical infrastructure)

**2. API Token Rotation Policy**
- Establish schedule for rotating tokens (every 3-6 months)
- Limits window of exposure if token is stolen
- Effort: 30 mins setup, 15 mins per rotation
- Risk reduction: MEDIUM

**3. AppArmor Profiles for Critical Services**
- Sandbox Claude Code, Gemini, SSH daemon
- Prevents compromised process from accessing full filesystem
- Effort: 45 mins
- Risk reduction: MEDIUM (LXC already isolated from Proxmox)

### LOW PRIORITY (Ongoing)

**4. Quarterly Security Audits**
- Every 3 months (Jan 1, Apr 1, Jul 1, Oct 1)
- Re-run Session 69 comprehensive audit
- Check for new vulnerabilities, permission drift, etc.
- Effort: 1-2 hours per audit
- Risk reduction: LOW-MEDIUM (prevents gradual degradation)

### Recommended Next Session Order
1. Secrets management (pass) - Encrypt API tokens
2. Token rotation policy - Schedule token changes
3. AppArmor - Defense in depth
4. Audits - Schedule quarterly checks

---

## Commands Executed

```bash
# File permissions (6 changes)
chmod 600 ~/.bashrc
chmod 755 ~/.gemini
find ~/scripts -type d -exec chmod 755 {} \;
find ~/scripts -type f -name "*.sh" -exec chmod 755 {} \;
find ~/scripts -type f ! -name "*.sh" -exec chmod 644 {} \;

# SSH hardening (single command with 6 settings)
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup && \
sudo sed -i 's/^X11Forwarding yes/X11Forwarding no/; \
s/^#MaxAuthTries 6/MaxAuthTries 3/; \
s/^#MaxSessions 10/MaxSessions 5/; \
s/^#Compression delayed/Compression delayed/; \
s/^#ClientAliveInterval 0/ClientAliveInterval 1200/; \
s/^#ClientAliveCountMax 3/ClientAliveCountMax 2/' /etc/ssh/sshd_config && \
sudo sshd -T && \
sudo systemctl restart ssh

# UFW firewall setup (single command)
sudo ufw default deny incoming && \
sudo ufw default allow outgoing && \
sudo ufw allow 22/tcp && \
sudo ufw enable

# Verification
grep -E "^X11Forwarding|^MaxAuthTries|^MaxSessions|^Compression|^ClientAlive" /etc/ssh/sshd_config
sudo sshd -T
cat /etc/ufw/ufw.conf | grep ENABLED
netstat -tlnp | grep :22
timeout 2 bash -c "echo >/dev/tcp/localhost/22"
```

---

## Decisions Made

### File Permissions (755 vs 700)
- **Decision:** `.gemini/` = 755, `~/scripts/` = 755
- **Rationale:** Enables multi-AI agent collaboration while maintaining owner write control
- **Risk:** None - both agents run as same user; visibility doesn't increase risk

### SSH Hardening Selection
- **Included:** X11Forwarding, MaxAuthTries, MaxSessions, Compression, ClientAlive
- **Excluded:** Rate limiting (not needed with key-only auth + MaxAuthTries)
- **Reasoning:** Balanced security vs operational convenience

### UFW Readiness
- **Status:** ✅ Verified safe for SSH access
- **Port:** 22/tcp confirmed open between desktop and LXC 102
- **Next:** Ready to enable UFW in Session 71

---

## Lessons Learned

1. **Permission model:** 755 for shared resources is appropriate when all processes run as same user
2. **SSH complexity:** Each setting serves specific purpose; clear decision-making helps avoid over-hardening
3. **Multi-agent architecture:** Requires thinking about access patterns for future systems
4. **Verification first:** Always confirm remote access works before enabling restrictive firewalls

---

## Next Steps

**Session 71 (Immediate):**
1. Create UFW firewall rules
2. Enable UFW (verified safe for SSH)
3. Validate SSH still works

**Future Sessions:**
1. ✅ Complete all HIGH PRIORITY tasks
2. MEDIUM PRIORITY: AppArmor, secrets management
3. ONGOING: Quarterly security audits

---

## References

- **Session 69:** LXC 102 comprehensive security audit and sudoers fix
- **CLAUDE.md:** Multi-AI agent architecture guidelines
- **Documentation:** `/home/sleszugreen/docs/claude-sessions/`

---

**Session status:** ✅ COMPLETE - All HIGH PRIORITY tasks finished
**All changes verified:** Yes ✅
**SSH remote access:** ✅ Confirmed working with MobaXterm
**Firewall active:** ✅ UFW enabled and verified
**Ready for next session:** Yes - Secrets management (pass) recommended

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
