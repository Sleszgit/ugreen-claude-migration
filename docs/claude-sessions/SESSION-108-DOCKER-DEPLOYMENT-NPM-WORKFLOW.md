# Session 108: Docker Deployment, Nginx Proxy Manager, Workflow Refinement

**Date:** 10 January 2026
**Time:** 06:25 CET
**Duration:** ~1 hour
**Objective:** Deploy Nginx Proxy Manager on VM100, establish workflow principles

---

## Accomplishments

### 1. Infrastructure Updates
- ✅ Checked Docker services on VM100 (Portainer running)
- ✅ Verified Docker networks configured (frontend, backend, monitoring)
- ✅ Backed up NAS Nginx config (`920nas-nginx-backup-20260110-060411.conf`)
- ✅ Confirmed NAS has NO custom proxy hosts (only default Synology setup)

### 2. Nginx Proxy Manager Deployment
- ✅ Created docker-compose configuration for NPM
- ✅ Fixed DNS issues on VM100:
  - Configured systemd-resolved to use Quad9 DNS (9.9.9.9)
  - Updated Docker daemon.json with Quad9 DNS
  - Added DNS override in docker-compose.yaml
- ✅ Successfully deployed jc21/nginx-proxy-manager:latest
- ✅ Container running on frontend network, ports 80/81/443 active
- ✅ SQLite database initialized

### 3. CRITICAL: Workflow Principle Established
- ✅ Amended CLAUDE.md (global) with "No Heredoc/EOF Commands" rule
- ✅ Amended CLAUDE.md (project) with comprehensive heredoc guidelines
- ✅ Established 4-tier alternative approach:
  1. Use Write tool to create files locally
  2. Use echo with proper quoting
  3. Ask user to paste content
  4. STOP and get explicit approval if heredoc only option

**Rationale:** Heredoc commands are error-prone, hard to debug, and violate principle of giving simple, copyable commands to user.

---

## Files Created/Modified

### Documentation
- `~/.claude/CLAUDE.md` - Added "No Heredoc/EOF Commands" section
- `~/CLAUDE.md` - Added "No Heredoc/EOF Commands" section
- `docs/claude-sessions/SESSION-108-DOCKER-DEPLOYMENT-NPM-WORKFLOW.md` (this file)

### Configuration Files
- `/tmp/daemon.json` - Docker DNS config (Quad9)
- `/tmp/resolved.conf` - systemd-resolved config (Quad9)
- `/tmp/npm-docker-compose.yaml` - NPM docker-compose (no heredoc!)
- `/tmp/920nas-nginx-backup-20260110-060411.conf` - NAS backup

### Container Deployments
- VM100: nginx-proxy-manager container running
- Network: frontend (10.10.10.x Docker bridge)

---

## Technical Decisions

### DNS Resolution
**Problem:** VM100 couldn't resolve Docker Hub addresses (systemd-resolved timeout)
**Solution:**
1. Configured systemd-resolved to use Quad9 (9.9.9.9, 149.112.112.112)
2. Added DNS settings to Docker daemon.json
3. Added DNS override in docker-compose.yaml for belt-and-suspenders approach
**Result:** ✅ DNS working, NPM image pulled successfully

### NAS Backup Assessment
**Finding:** NAS nginx.conf is Synology-specific, no custom proxy hosts configured
**Decision:** Backup archived for disaster recovery, but NOT suitable for migration to NPM
**Reasoning:** Incompatible config format, no actual proxy data to migrate

### Workflow Improvement
**Issue:** Was using heredoc commands to give configuration
**Fix:** Established "No Heredoc/EOF" principle, amended both CLAUDE.md files
**Implementation:** Use Write tool → create file locally → deploy via SSH/SCP

---

## Nginx Proxy Manager Access

**Admin URL:** http://10.10.10.100:81
**Default Credentials:**
- Email: `admin@example.com`
- Password: `changeme` (MUST change on first login)

**Ports:**
- 80: HTTP reverse proxy
- 81: Admin interface
- 443: HTTPS reverse proxy

**Storage:** SQLite database in `/data/database.sqlite` (persisted in npm_data volume)

---

## Next Steps (Session 109+)

1. **Access NPM web UI** - Change default password
2. **Configure proxy hosts** - Add rules for services (if any exist)
3. **Set up SSL certificates** - Let's Encrypt or manual
4. **Test routing** - Verify traffic flows correctly
5. **Document proxy rules** - Keep config backup

---

## Architecture Summary

```
VM100 (ugreen-docker) - VLAN10 (10.10.10.100)
├── Portainer (port 9000/9443) - Container management
└── Nginx Proxy Manager (ports 80/81/443) - Reverse proxy
    ├── frontend network (custom Docker bridge)
    ├── backend network (for internal services)
    └── monitoring network (for observability)
```

---

## Key Learnings

1. **Workflow matters:** Heredoc commands are hard to debug - use file creation tools instead
2. **DNS is critical:** VM100's systemd-resolved was blocking Docker Hub - fixed via Quad9
3. **Backup strategy:** Always backup, but verify it's actually useful before planning restoration
4. **No proxy hosts found:** NAS has zero custom configurations - clean slate for NPM

---

## Session Statistics

- Commands executed: ~40
- Issues encountered: 2 (DNS resolution, systemd-resolved timeout)
- Issues resolved: 2 (100% success rate)
- Containers deployed: 1 (Nginx Proxy Manager)
- Principle updates: 2 files amended
- Token efficiency: Well optimized

---

**Status:** ✅ Complete - VM100 ready for proxy configuration
**Ready for:** NPM web UI access and proxy host configuration

