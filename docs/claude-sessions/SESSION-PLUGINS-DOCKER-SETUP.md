# Session: Claude Code Plugins & Docker MCP Setup

**Date:** 2025-12-24
**User:** sleszugreen
**Device:** UGREEN DXP4800+ Proxmox (LXC 102 - ugreen-ai-terminal)
**Focus:** Claude Code plugin installation and Docker MCP Toolkit evaluation

---

## Summary

Reviewed Claude Code plugin ecosystem, installed 5 recommended plugins from official marketplace, and evaluated Docker MCP Toolkit for infrastructure monitoring/Docker container management on Proxmox host.

---

## Key Findings

### Plugin Marketplace Validation

**Official Marketplace = Security & Validation:**
- Plugins are audited by Anthropic
- Permission-controlled with pre-approval
- Hook monitoring for command injection, XSS, eval usage, pickle deserialization
- Maintained with regular updates

**Third-Party Plugins = Higher Risk:**
- Minimal/no vetting
- Known exploit vectors: hooks can bypass permissions
- License compliance responsibility falls on user
- Supply chain risks exist

**Sources:**
- [Claude Code Plugin Marketplaces - Docs](https://code.claude.com/docs/en/plugin-marketplaces)
- [Hijacking Claude Code via Injected Marketplace Plugins - PromptArmor](https://www.promptarmor.com/resources/threat-intel/hijacking-claude-code-via-injected-marketplace-plugins)

---

## Installed Plugins (5 Total)

✅ **Status:** All installed and enabled

| Plugin | Type | Purpose | Use Case |
|--------|------|---------|----------|
| **github** | External MCP | GitHub repo management, PR reviews, issue creation | NAS transfer, Proxmox hardening projects |
| **security-guidance** | Hook | Security warnings during code edits | Critical for infrastructure/hardening work |
| **code-review** | Agent | Automated code review with confidence scoring | Infrastructure automation script review |
| **pr-review-toolkit** | Agent | Specialized PR review (comments, tests, error handling) | GitHub workflow automation |
| **commit-commands** | Slash Commands | Git workflow commands (`/commit`, `/push`, `/pr`) | Scripting & infrastructure commits |

**Not in marketplace (evaluated):**
- Web Clipper - Use built-in `/fetch` command instead
- Docker tools - Addressed via Docker MCP Toolkit
- System Monitoring - Use Proxmox tools + bash MCP

---

## Docker MCP Toolkit Investigation

**Current Status:** NOT INSTALLED
**Location:** Proxmox host (192.168.40.60)
**Docker Installation:** Not found

### Decision: Install Docker on Proxmox Host

**Rationale:**
- Run Docker for containerized MCP servers
- Separate from LXC container infrastructure
- Standard approach for Linux homelab setups
- Supports Docker MCP Toolkit (200+ pre-built MCP servers)

**Installation Method:** Docker Engine from official repository (NOT Docker Desktop)
- Appropriate for Linux servers
- Latest security updates
- Clean management alongside LXC containers

**Prerequisites:**
- sudo access (available - user is sudoer)
- Debian/Ubuntu compatible (Proxmox is Debian-based)

**User Decision:** Installation pending approval

---

## Technical Notes

### MCP Servers Currently Configured

**In LXC 102 container (.claude.json):**
- `filesystem` - Local file access (stdio)
- `bash` - Shell commands (stdio)
- `github` - GitHub integration (HTTP)

**Planned for Proxmox host:**
- Docker MCP Toolkit (multiple containerized servers)
- Will be accessible from Claude Code in container via Docker socket/API

### User Configuration Context

From `~/.claude/CLAUDE.md`:
- **Device:** UGREEN DXP4800+ Proxmox
- **Container:** LXC 102 (ugreen-ai-terminal)
- **User:** sleszugreen (sudo access)
- **Storage:** ZFS pools (nvme2tb), compression enabled
- **Services:** Samba/Windows sharing, NAS management, SSH, Proxmox hardening
- **Projects:** ai-projects, nas-transfer, proxmox-hardening
- **Skills:** Infrastructure automation, security hardening, homelab management

---

## Next Steps (If Proceeding)

1. **Install Docker Engine on Proxmox host**
   ```bash
   # Run ON PROXMOX HOST
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y ca-certificates curl gnupg lsb-release
   curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```

2. **Verify Docker installation**
   ```bash
   docker --version
   docker ps
   ```

3. **Configure Docker MCP Toolkit** (if Docker installed successfully)
   - Reference: [Docker MCP Toolkit Setup Guide](https://docs.docker.com/guides/genai-claude-code-mcp/claude-code-mcp-guide/)

4. **Update Claude Code MCP configuration** to connect to Docker host

---

## Important Notes

⚠️ **Critical Decision:** User will NOT run Docker in LXC 102 container. Docker will run on Proxmox host only.

- Keeps container environment focused on Claude Code/development
- Leverages host-level resources for Docker services
- Cleaner separation of concerns (infrastructure vs. development)

---

## References

- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins)
- [Docker MCP Toolkit](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/)
- [Claude Code MCP Guide](https://docs.docker.com/guides/genai-claude-code-mcp/claude-code-mcp-guide/)
- [Add MCP Servers to Claude Code - Docker Blog](https://www.docker.com/blog/add-mcp-servers-to-claude-code-with-mcp-toolkit/)

---

**Session Status:** Plugin installation complete. Docker installation pending user approval.
