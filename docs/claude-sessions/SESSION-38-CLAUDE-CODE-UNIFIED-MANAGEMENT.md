# SESSION 38: Unified Claude Code Management - UGREEN Central Instance

**Date:** 27 Dec 2025  
**Location:** UGREEN LXC 102  
**Goal:** Set up SSH from UGREEN Claude Code to homelab for unified management  

---

## Summary

User wants to use Claude Code to manage both UGREEN and homelab from a single instance, avoiding setup duplication and context loss from running multiple Claude Code instances.

## Initial Assessment

**Current State:**
- UGREEN: Claude Code installed in LXC 102 ✅
- Homelab: Claude Code already installed but not actively used
- Connection: SSH between UGREEN container → homelab NOT configured
- API access: UGREEN has Proxmox API tokens configured

**Problem Identified:**
- Running duplicate Claude Code instances would create context divergence
- Session notes, decisions, and knowledge would split across instances
- Configuration changes wouldn't sync between instances

**Solution Decided:**
- Keep Claude Code as **single source of truth on UGREEN**
- Configure SSH from UGREEN container → homelab Proxmox host
- Use homelab Claude Code instance only for local physical work (independent)
- Manage homelab infrastructure remotely from UGREEN instance with full context

---

## Next Steps

### Before SSH Setup
Investigate existing homelab security:
1. Check for Proxmox API tokens for homelab
2. Determine homelab Proxmox IP/hostname
3. Identify existing security:
   - SSH key authentication
   - Firewall rules
   - Special ports
   - User permissions

### After Investigation
- Plan SSH setup without disrupting existing security
- Configure SSH key authentication if needed
- Test connection from UGREEN container to homelab

---

## Key Decisions

✅ **Single Claude Code instance** - UGREEN LXC 102 as primary  
✅ **SSH as connection method** - More direct than API-only  
⏳ **Preserve existing homelab security** - Investigate before configuring  

---

**Status:** Pending homelab security investigation
