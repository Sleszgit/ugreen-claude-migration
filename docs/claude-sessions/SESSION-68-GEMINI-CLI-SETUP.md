# Session 68: Gemini CLI Setup in LXC 102

**Date:** 31 Dec 2025
**Location:** LXC 102 (ugreen-ai-terminal)
**Duration:** Installation and verification
**Status:** ✅ Complete

---

## Overview

Installed Google's official Gemini CLI as a standalone tool in LXC 102, independent of Claude Code. This allows direct CLI access to Gemini for text analysis, code review, and interactive conversations.

---

## What Was Accomplished

### 1. Initial Investigation: Skill vs. Standalone CLI
- Created a Claude Code skill to integrate Gemini (approach 1)
- Analyzed Google's official Gemini CLI setup instructions (approach 2)
- Determined official CLI was superior to custom skill
- Advantages:
  - Official tool from Google (better maintained)
  - Simpler to use
  - Full interactive mode support
  - No dependencies on Claude Code

### 2. Security Analysis
- Identified actual risks with API key exposure (not financial due to no billing)
- Main risks: rate limit exhaustion, data exposure if sensitive data sent to Gemini
- Discussed API key storage methods (bashrc vs. separate file)
- Concluded: minimal security difference, but decided on secure setup anyway

### 3. Network Verification
- Verified LXC 102 can reach Google's API servers
- ✅ DNS working
- ✅ Connection to generativelanguage.googleapis.com working

### 4. Installation Steps

#### Node.js (v20.19.6)
- Already installed on system
- Verified with `node -v` and `npm -v`
- No installation needed

#### Gemini CLI
- Installed globally using `npm install -g @google/gemini-cli --prefix ~/.local`
- Secure method: uses user directory, no `--unsafe-perm` flag
- Version: 0.22.5

#### API Key Configuration
- Created `~/.gemini-api-key` with secure permissions (chmod 600)
- File contains: `export GEMINI_API_KEY="..."`
- Sourced automatically in `~/.bashrc` on shell startup
- Keeps key isolated from bashrc itself

#### PATH Configuration
- Updated `~/.bashrc` to include `$HOME/.local/bin` in PATH
- Added line to source `~/.gemini-api-key` on shell startup

### 5. Verification

**Test 1: Version check**
```bash
gemini --version
# Output: 0.22.5
```

**Test 2: Simple prompt**
```bash
gemini "Say 'Gemini CLI is working!' exactly in those words"
# Output: Gemini CLI is working!
```

**Test 3: Interactive mode**
```bash
gemini "What is the capital of France?"
# Output: The capital of France is Paris.
```

---

## Files Modified/Created

### Created
- `~/.gemini-api-key` - API key file (chmod 600, NOT committed to git)

### Modified
- `~/.bashrc` - Added Gemini CLI PATH and API key sourcing (lines 125-127)

---

## Setup Details

**Installation location:** `~/.local/bin/gemini`
**Configuration:** Auto-loaded from `~/.bashrc`
**API Key:** Stored in `~/.gemini-api-key` (chmod 600)

**Why this setup:**
1. **--prefix ~/.local** - Avoids need for `--unsafe-perm` with sudo
2. **Separate API key file** - Isolates sensitive data, easier to manage
3. **Auto-load in bashrc** - Convenient for daily use
4. **chmod 600** - Restricts access (though within same user context, minimal difference)

---

## Usage Examples

```bash
# Single question
gemini "Explain quantum computing"

# Analyze a file
cat script.sh | gemini "Review this for security issues"

# Interactive chat
gemini

# Code review
gemini --all-files "Check for bugs in this codebase"

# Help
gemini --help
```

---

## Important Notes

### Security Considerations
- ⚠️ API key has no billing method attached (safe financially)
- ⚠️ But you will send **sensitive data** to Gemini
- ⚠️ If API key is compromised, attacker can see all queries
- 🔍 **Future action:** Audit LXC 102 security in next session
  - SSH access controls
  - Network isolation
  - Process security
  - Credential storage

### Differences from Skill Approach
- ✅ Official tool (better maintained)
- ✅ Standalone (doesn't require Claude Code)
- ✅ Interactive mode
- ✅ Full feature support
- ✅ Direct CLI access without orchestration

---

## Next Steps

**Session 69 - LXC 102 Security Audit:**
- Verify SSH key-only access
- Check firewall rules and network isolation
- Review process/service security
- Document credential storage practices
- Determine if additional hardening needed given sensitive data usage

---

## Command Reference

| Task | Command |
|------|---------|
| Interactive chat | `gemini` |
| Single question | `gemini "your question"` |
| Analyze file | `cat file.txt \| gemini "analyze"` |
| Project scan | `gemini --all-files "review code"` |
| Help | `gemini --help` |
| Version | `gemini --version` |

---

## Session Summary

Successfully installed Google's official Gemini CLI in LXC 102 with secure configuration. The tool is fully functional and ready for daily use. Identified security considerations related to sensitive data handling and planned a follow-up security audit for the next session.

---

**Last Updated:** 31 Dec 2025
**Next Session:** Security audit of LXC 102
