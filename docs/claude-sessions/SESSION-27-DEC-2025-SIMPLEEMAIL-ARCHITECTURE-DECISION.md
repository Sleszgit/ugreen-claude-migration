# Session: SimpleLogin Architecture Decision & Services Finalization

**Date:** 27 December 2025  
**Status:** ✅ COMPLETE - Ready for implementation after copy operation  
**Focus:** Email aliasing solution finalized, technical architecture resolved

---

## Session Summary

Reviewed homelab services plan from Session 26 and made critical decision on email aliasing solution. Compared SimpleLogin vs Anondaddy, evaluated architectural constraints, and designed free self-hosted solution that meets all requirements.

---

## Key Decision: SimpleLogin + Mail Relay Architecture

### Why SimpleLogin Over Anondaddy?

**User Requirement:** Different sender names per alias (essential for user)

**Feature Comparison:**

| Feature | SimpleLogin | Anondaddy |
|---------|-------------|-----------|
| Per-alias sender names | ✅ YES | ❌ NO (global only) |
| Open source | ✅ Yes | ✅ Yes |
| Self-hosting | ✅ Yes | ✅ Yes |
| Spam filtering | ❌ No | ✅ Rspamd |
| Custom domain (free) | ❌ Cloud only | ❌ Premium only |

**Decision:** SimpleLogin for per-alias customization (critical feature)

---

## Technical Architecture: Solving Port 25 Constraint

### The Problem
User constraints:
- Can't open port 25 (ISP blocks it)
- Doesn't want to open any ports
- Has custom domain
- Wants free solution
- Needs self-hosted (data privacy)

Self-hosted SimpleLogin normally requires:
- Port 25 OPEN (receive SMTP from internet)
- MX records pointing to their server

### The Solution: Mail Relay Pattern

```
Internet Mail Servers
         ↓
ImprovMX (free relay service on port 25)
         ↓
MX records: yourdomain.com → ImprovMX
         ↓
ImprovMX forwards to YOUR server
(outgoing connection on port 587/465)
         ↓
Self-Hosted SimpleLogin on UGREEN VM 100
         ↓
Forwards to user's real inbox
```

**Key Insight:** Port 587/465 are OUTGOING connections (no firewall open needed)

### Why This Works
- ✅ No ports opened on user's side
- ✅ ImprovMX handles port 25 (relay's responsibility)
- ✅ SimpleLogin pushes/pulls mail via outgoing connection
- ✅ Completely free
- ✅ Data stays self-hosted (SimpleLogin + ImprovMX config)

---

## Services List - FINALIZED

### UGREEN VM 100 (Primary - 13 services)

**Phase 1: Infrastructure Foundation**
1. Portainer CE (Docker management UI)
2. Netbird (mesh VPN - zero-trust external access)
3. Authentik (centralized SSO/OAuth2)
4. Nginx Proxy Manager (reverse proxy + SSL)
5. Uptime Kuma (service monitoring dashboard)

**Phase 2: Media Servers**
6. Plex (media streaming with transcoding)
7. Jellyfin (open-source media server)

**Phase 3: Email & Documents**
8. SimpleLogin (email aliases with per-alias sender names)
   - With ImprovMX relay backend
9. Paperless-ngx (document scanning/management)
10. Nextexplorer (file browser UI)

**Phase 4: Utilities**
11. Stirling PDF (PDF manipulation tools)
12. Pairdrop (secure file sharing)
13. UniFi Network MCP (network management)

### Homelab VM 100 (Secondary - 3 services - unchanged)
1. Kavita (comics/ebooks)
2. Audiobookshelf (audiobooks)
3. Immich (photo management)

---

## Technical Decisions

### Email Architecture
- **Cloud option rejected:** Free tier doesn't support custom domains
- **Self-hosted with relay chosen:** Free, full-featured, custom domain support
- **Relay service:** ImprovMX (free tier available, reliable)
- **Configuration:** SimpleLogin outbound → ImprovMX inbound relay
- **MX records:** Point to ImprovMX, not to user's server

### Storage Layout
- Media path: `/mnt/media` (20TB SATA array)
- Service data: 250GB on nvme2tb ZFS pool
- Database storage: PostgreSQL/Redis in containers

### Network Configuration
- Primary subnet: 192.168.40.0/24 (management)
- Service IPs: 192.168.40.50-62 (UGREEN VM 100)
- External access: Netbird mesh VPN (no port forwarding)
- Firewall: Default deny, opened only for internal + Netbird

---

## Implementation Status

### Current Blocker
**File copy operation in progress:** User copying thousands of files from secondary NAS to UGREEN 20TB array. 

**Decision:** Do NOT start any implementation until copy completes.

**Reason:**
- Service installation = heavy disk I/O
- Docker image pulls = network bandwidth
- Both would compete with copy operation
- Risk of file corruption or incomplete copy

### Safe Implementation Sequence (Post-Copy)
1. ✅ Copy operation completes
2. → Hardening: Apply VM 100 security baseline
3. → Phase 1: Deploy infrastructure (Portainer, Netbird, Authentik)
4. → Phase 2: Deploy media servers (Plex, Jellyfin)
5. → Phase 3: Deploy email + documents (SimpleLogin + relay config, Paperless)
6. → Phase 4: Deploy utilities
7. → Phase 5: Configure external access

---

## Key Questions Answered

**Q: Why not use Anondaddy?**  
A: Lacks per-alias sender name customization (critical user requirement)

**Q: Do we need to open port 25?**  
A: No. Mail relay service handles port 25 on their infrastructure. User only needs outgoing connection on 587/465.

**Q: Will hardening break the copy operation?**  
A: No. Firewall rules for file transfer (SMB/NFS) won't be affected.

**Q: Will service installation interfere with copy?**  
A: Yes. Should wait until copy completes to avoid I/O contention.

**Q: Is SimpleLogin free?**  
A: Cloud tier is free but doesn't support custom domains. Self-hosted is free, relay service (ImprovMX) is free.

---

## Resources Referenced

- [SimpleLogin Pricing](https://simplelogin.io/pricing/)
- [SimpleLogin Custom Domain Docs](https://simplelogin.io/docs/custom-domain/add-domain/)
- [SimpleLogin vs AnonAddy Comparison - SaaSHub](https://www.saashub.com/compare-anonaddy-vs-simplelogin)
- [Free SMTP Servers 2025 Comparison](https://www.emailtooltester.com/en/blog/free-smtp-servers/)
- [AnonAddy Docker Setup](https://github.com/anonaddy/docker)
- [SimpleLogin Self-Hosting GitHub](https://github.com/simple-login/app)

---

## Session Artifacts

**Session Type:** Decision-making + Architecture design  
**Duration:** Extended analysis session  
**Decisions Made:** 3 critical architectural choices  
**Documents Updated:** Service list finalized, architecture documented

---

## Next Session Checklist

When copy operation completes, user will reopen session to:
- [ ] Verify copy operation success (validate file integrity)
- [ ] Implement VM 100 security hardening
- [ ] Begin Phase 1 service deployment
- [ ] Create detailed Docker compose files for each service

---

**Session Status:** ✅ COMPLETE - Awaiting user notification that copy operation is finished

**Previous Session:** SESSION-26-DEC-2025-INFRASTRUCTURE-PLANNING.md  
**Related Docs:**
- `/home/sleszugreen/.claude/plans/partitioned-tumbling-cloud.md` (main deployment plan)
- `INFRASTRUCTURE.md` (network & storage details)
- `VM-CREATION-GUIDE.md` (VM setup reference)

---

**Timestamp:** 27 Dec 2025, 14:30 CET  
**Context Size:** Session complete, ready for implementation phase
