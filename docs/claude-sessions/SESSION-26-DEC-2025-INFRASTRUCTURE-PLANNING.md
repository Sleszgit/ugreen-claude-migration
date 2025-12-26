# Session: Infrastructure Planning & Service Deployment Strategy

**Date:** 26 December 2025
**Duration:** Extended planning session
**Outcome:** Comprehensive deployment plan for 17 services across UGREEN and Homelab

---

## Session Summary

Conducted detailed infrastructure planning for homelab service deployment. Initial plan assumed 8GB RAM on UGREEN; discovered actual hardware specs during review (64GB RAM on UGREEN, 98GB on Homelab). This led to significant plan revision with UGREEN as primary deployment target instead of Homelab.

---

## Key Discoveries

### Infrastructure Corrections
- **UGREEN:** Actually has **64GB DDR5 RAM** (not 8GB as documented)
  - Upgraded since documentation was written
  - Ample capacity for all services
- **Homelab:** **98GB RAM** (not 96GB as documented)
  - Still has plenty of headroom

### UGREEN VM 100 Status
- ✅ **Already Operational** - Ubuntu installed, Docker deployed
- No blocker for immediate service deployment
- Ready for Phase 1

---

## Services Finalized

### Complete Inventory (17 services)

**UGREEN (Primary) - 13 services:**
1. Portainer CE (Docker management)
2. Netbird (mesh VPN)
3. Authentik (SSO/OAuth2)
4. Nginx Proxy Manager (reverse proxy)
5. Uptime Kuma (monitoring)
6. **Plex** (media server) - NEW
7. **Jellyfin** (media server) - NEW
8. SimpleLogin (email aliases)
9. Paperless-ngx (document management)
10. Nextexplorer (file browser)
11. Stirling PDF (PDF tools)
12. Pairdrop (file sharing)
13. UniFi Network MCP (network mgmt)

**Homelab (Secondary - Unchanged) - 3 services:**
1. Kavita (comics/ebooks)
2. Audiobookshelf (audiobooks)
3. Immich (photo management)

### Additional Services Considered (Not in Plan)
- Kanata (keyboard mapping) - CLI tool, deploy as needed
- Compactor (file compression) - CLI tool, deploy as needed

---

## Architecture Decisions

### UGREEN as Primary
**Rationale:**
- 64GB RAM same as Homelab, but closer to storage
- Direct access to 20TB SATA array (optimal for Plex/Jellyfin transcoding)
- Lower power consumption (15W idle)
- Dedicated NAS hardware
- VM 100 already operational (no installation delays)
- Simpler deployment (single VM consolidation)

### Homelab Secondary Role
- Keep existing services running (no changes)
- Media services accessible via Netbird VPN from outside
- Acts as backup/secondary redundancy

### External Access Strategy
- **Netbird mesh VPN** - zero-trust, no port forwarding
- All services accessible from outside via encrypted tunnel
- Better than Tailscale (fully self-hosted)
- Works on mobile, hotel WiFi, etc.

---

## Deployment Plan

### 5 Phases (7-10 days total)

| Phase | Focus | Timeline | Services |
|-------|-------|----------|----------|
| 1 | Infrastructure foundation | 2-3 days | Portainer, Netbird, Authentik, Nginx PM, Uptime Kuma |
| 2 | Media servers | 1-2 days | Plex, Jellyfin |
| 3 | Email & documents | 2-3 days | SimpleLogin, Paperless-ngx, Nextexplorer |
| 4 | Utilities | 1 day | Stirling PDF, Pairdrop, UniFi MCP |
| 5 | External access | 1 day | Configure Netbird for Homelab media access |

### Static IP Allocation
- 192.168.40.50-62: Services on UGREEN VM 100
- 10.10.10.10: Homelab VM 100 (Kavita/Audiobookshelf)
- 192.168.40.37-40: Homelab other services

---

## Key Requirements Implemented

✅ **External Access Without Port Forwarding**
- Netbird mesh VPN for all services
- Zero-trust architecture
- Device authentication required

✅ **Self-Hosted Email Aliasing**
- SimpleLogin for disposable email addresses
- Works with user's own domain
- SMTP relay configuration

✅ **Media Services Optimization**
- Plex + Jellyfin on UGREEN (close to storage)
- Hardware transcoding support
- Homelab media kept separate (Kavita, Audiobookshelf, Immich)

✅ **Centralized SSO**
- Authentik for single sign-on
- Integrates with Portainer, Paperless-ngx
- 2FA support

✅ **Monitoring & Management**
- Portainer CE for Docker container management
- Uptime Kuma for service monitoring
- Nginx Proxy Manager for reverse proxy/SSL

---

## Differences from Original Plan

| Aspect | Original | Revised | Reason |
|--------|----------|---------|--------|
| Primary | Homelab | UGREEN | Closer to storage, VM already ready |
| RAM specs | 96GB/8GB | 98GB/64GB | Actual verified hardware |
| Homelab changes | Expand VM | None | UGREEN has ample resources |
| Media location | Homelab | UGREEN | Direct storage access for transcoding |
| VM fixes | Needed | Not needed | Already deployed |
| Timeline | 8-12 days | 7-10 days | Faster due to consolidation |
| Services | 11 new | 13 new | Added Plex + Jellyfin |

---

## Plan Documents

**Main Plan:** `/home/sleszugreen/.claude/plans/partitioned-tumbling-cloud.md`
- 525 lines
- Complete deployment strategy
- Docker-compose templates (placeholders)
- Phase-by-phase procedures
- Troubleshooting guide
- Success criteria

**Todo List:** 20 items tracked
- Pre-deployment (2 items)
- Phase 1-4 implementation (14 items)
- Phase 5 external access (1 item)
- Post-deployment (2 items)
- Post-deployment documentation (1 item)

---

## Next Steps

1. **Phase 1 Implementation** - Deploy Portainer CE, Netbird, Authentik
2. **Create Docker Compose files** - Detailed YAML for each service
3. **Storage configuration** - Set up media paths on 20TB array
4. **Domain setup** - Configure SimpleLogin with user's domain
5. **Testing** - Verify each phase before proceeding

---

## Technical Notes

### Storage Layout
- Media path: `/mnt/media` → 20TB SATA array
- Service data: 250GB allocated on nvme2tb ZFS pool
- Database storage: PostgreSQL, Redis containers

### Network Configuration
- Primary: 192.168.40.0/24 (management)
- Secondary: 10.10.10.0/24 (homelab isolated)
- Management: 192.168.99.0/24 (UniFi)
- Firewall: Internal-only by default, Netbird for external

### Resource Allocation
- UGREEN VM 100: 48GB RAM, 250GB disk
- Homelab VM 100: 32GB RAM, 120GB disk (unchanged)
- Total services: 17 containers (13 UGREEN, 3 Homelab)

---

## Session Metadata

**Tools Used:**
- EnterPlanMode workflow
- Explore agent for infrastructure analysis
- Comprehensive planning and documentation

**Key Files Modified:**
- Created: `/home/sleszugreen/.claude/plans/partitioned-tumbling-cloud.md`
- Updated: Todo list (20 items)

**Decisions Made:**
- ✅ UGREEN as primary (unanimous)
- ✅ Netbird for external access (no port forwarding)
- ✅ Plex + Jellyfin on UGREEN (media optimization)
- ✅ Homelab secondary (cost of change = 0)
- ✅ 5 phase deployment (manageable chunks)

---

**Session Status:** ✅ COMPLETE - Plan finalized, ready for implementation
