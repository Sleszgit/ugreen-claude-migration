# Session 136: Mediaserver LXC Planning - Naming & Architecture

**Date:** January 18, 2026
**Status:** 🔄 IN PROGRESS - Planning phase, awaiting user architecture decisions
**Duration:** ~5 minutes (planning session)

---

## Objective

User requested advice on creating an unprivileged LXC container for media players (Plex/Jellyfin) + arr stack (Sonarr/Radarr/Lidarr/Prowlarr) on UGREEN infrastructure.

---

## Session Work Completed

### ✅ Network Context Reviewed
- Examined existing homelab structure (VM100 Docker, NFS mounts, media storage)
- Reviewed VLAN topology (VLAN 10: services, VLAN 20: test)
- Confirmed media collections available on ZFS pools

### ✅ Naming Convention Determined
**Recommendation:** `ugreen-mediaserver`

**Rationale:**
- Follows naming pattern: `[location]-[purpose]`
- Consistent with existing containers (ugreen-ai-terminal, ugreen-docker-test)
- Clear purpose: media playback + arr stack
- Flexible (not locked to specific player software)
- Appropriate for unprivileged LXC

**Alternatives considered (rejected):**
- `ugreen-media-center` - too long
- `ugreen-streaming` - too generic
- `ugreen-arr-media` - implies arr focus
- `ugreen-plex` / `ugreen-jellyfin` - software-specific, inflexible

---

## Outstanding Questions - Awaiting User Input

Before proceeding with implementation planning:

1. **VLAN Placement**
   - VLAN 10 (services, 10.10.10.0/24)?
   - VLAN 20 (test, 10.20.20.0/24)?
   - Or management VLAN (40, 192.168.40.0/24)?

2. **Location Confirmation**
   - UGREEN Proxmox (192.168.40.60)? [assumed]
   - Or Homelab (192.168.40.40)?

3. **Storage Access**
   - NFS mount to `/storage/Media` (UGREEN)?
   - NFS mount to `/Seagate-20TB-mirror` (Homelab)?
   - Both?

4. **Resource Sizing**
   - CPU cores allocation?
   - RAM allocation?
   - Disk space for container OS + arr database?

5. **Service Stack Confirmation**
   - Media player: Plex or Jellyfin or both?
   - arr components: Sonarr, Radarr, Lidarr, Prowlarr?
   - Additional services? (Overseerr, Requestrr, etc.)

---

## Infrastructure Context Available

**From previous sessions:**

- **UGREEN Host:** 192.168.40.60, VLAN40 bridge (vmbr0), VLAN10 subinterface (vmbr0.10)
- **VM100:** Docker host on VLAN10 (10.10.10.100)
- **LXC102:** AI terminal (current location, VLAN40)
- **Media Storage:** 
  - `/storage/Media` on UGREEN (ZFS pool)
  - `/Seagate-20TB-mirror` on Homelab (ZFS, 11.1TB free)
- **NFS Mounts:** `/mnt/lxc102scripts/` bind mount accessible network-wide

---

## Files & Resources

**Session Location:** `/home/sleszugreen/docs/claude-sessions/SESSION-136-MEDIASERVER-LXC-PLANNING.md`

**Related Documentation:**
- Network topology: `~/.claude/ENVIRONMENT.yaml`
- VM/LXC best practices: `CLAUDE.md` section on ZFS datasets and unprivileged containers
- Docker setup analysis: `SESSION-124-DOCKER-SETUP-DECISION-24DEC2025.md`

---

## Next Session Actions

**When user provides architecture decisions:**

1. Design unprivileged LXC configuration
   - CPU/RAM/disk specs
   - VLAN and network interfaces
   - Storage mount strategy

2. Create provisioning script(s)
   - LXC creation script
   - Docker/compose setup for stack
   - NFS mount configuration

3. Document deployment plan
   - Step-by-step execution guide
   - Firewall rules needed
   - Verification checklist

4. Execute when approved

---

## Sign-Off

**Session Status:** 🔄 IN PROGRESS  
**Deliverable Status:** Naming decided, architecture questions outlined  
**Next:** Awaiting user input on VLAN, location, storage, and resource allocation

---

*Session 136 - Mediaserver LXC Planning*
*Awaiting user architecture decisions before implementation phase*

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
