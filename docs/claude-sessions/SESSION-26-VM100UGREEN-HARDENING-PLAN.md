# Session 26: VM 100 UGREEN - Docker Host Hardening Plan

**Date:** 26 December 2025
**Context:** UGREEN Proxmox (192.168.40.60), LXC 102 (ugreen-ai-terminal)
**Task:** Implement three-phase Docker host hardening for VM 100 UGREEN

---

## Session Overview

### What We Did
1. ✅ Read comprehensive hardening plan from `/home/sleszugreen/.claude/plans/scalable-stirring-rain.md`
2. ✅ Created Phase A execution todo list (8 tasks)
3. ✅ Clarified execution approach: Create scripts in LXC 102, user executes on VM 100
4. ✅ Determined SSH key setup needed (keys don't exist yet)
5. ✅ Decided on folder structure with VM namespacing

### Current State

**Plan Scope:**
- **Phase A (NOW):** VM access & Docker baseline (Scripts 00-05 + checkpoint)
  - SSH hardening (port 22022, keys-only)
  - UFW firewall
  - Docker daemon hardening
  - Docker network security
  - Portainer deployment
  - Duration: 1.5-2 hours

- **Phase B (LATER):** OS & container hardening
  - Kernel security, fail2ban, AppArmor, seccomp
  - Duration: 2-2.5 hours

- **Phase C (LATER):** Monitoring & compliance
  - Loki, Grafana, Netdata, Docker Bench
  - Duration: 1.5-2 hours

**VM Details:**
- Hostname: ugreen-docker
- IP: 192.168.40.60
- OS: Ubuntu 24.04 LTS
- Docker: 28.2.2
- Specs: 4 vCPU, 20GB RAM, 250GB disk

---

## Folder Structure (APPROVED)

**To distinguish between VMs on different Proxmox instances:**

```
LXC 102 Location (visible in both places):
/mnt/lxc102scripts/vm100ugreen/           ← UGREEN Proxmox VM 100
  ├── hardening/                           ← Phase A/B/C scripts
  │   ├── 00-pre-hardening-checks.sh
  │   ├── 01-ssh-hardening.sh
  │   ├── 02-ufw-firewall.sh
  │   ├── 03-docker-daemon-hardening.sh
  │   ├── 04-docker-network-security.sh
  │   ├── 05-portainer-deployment.sh
  │   ├── 05-checkpoint-phase-a.sh
  │   ├── backups/                         ← Config backups
  │   ├── CHECKPOINT-A-RESULTS.txt
  │   └── 99-emergency-rollback.sh
  └── general/                             ← Future VM 100 UGREEN scripts

Proxmox Host Location (same via bind mount):
/nvme2tb/lxc102scripts/vm100ugreen/       ← Auto-synced with above

Homelab VM 100 Scripts (separate):
/mnt/lxc102scripts/vm100homelab/          ← Different purposes, separate namespace
```

---

## Phase A Todo List

Status: PENDING EXECUTION

- [ ] Verify SSH access to VM 100 (192.168.40.60)
- [ ] Execute Script 00: Pre-hardening checks & backups
- [ ] Set up SSH key authentication (Script 01)
- [ ] Configure UFW firewall (Script 02)
- [ ] Harden Docker daemon (Script 03)
- [ ] Create Docker security networks (Script 04)
- [ ] Deploy Portainer web UI (Script 05)
- [ ] Run Phase A checkpoint verification (8 tests)

---

## Next Steps (Next Session)

### Before Starting Phase A Execution:

1. **Generate SSH Keys** (on Windows desktop if not already done)
   - Generate Ed25519 key pair
   - Save public key path for Script 01
   
2. **Prepare Execution Environment**
   - Create folder structure: `/mnt/lxc102scripts/vm100ugreen/hardening/`
   - Create all 6 Phase A scripts (00-05 + checkpoint)
   - Verify VM 100 SSH access works

3. **Execute Phase A Scripts** (in order)
   - Run Script 00, review backups
   - Run Script 01, test key auth on port 22022
   - Run Script 02-05 in sequence
   - Run Phase A checkpoint (must pass all 8 tests)

4. **Expected Outcome**
   - SSH accessible on port 22022 (keys-only)
   - UFW firewall active
   - Docker hardened with userns-remap
   - Custom Docker networks (frontend, backend, monitoring)
   - Portainer web UI running (https://192.168.40.60:9443)

---

## Key References

**Plan File:** `/home/sleszugreen/.claude/plans/scalable-stirring-rain.md`

**Safety Features:**
- Emergency rollback script (99-emergency-rollback.sh)
- Proxmox console access for lockout recovery
- All critical configs backed up before modification

**Success Criteria:**
All 8 Phase A checkpoint tests must pass before proceeding to Phase B

---

## Execution Notes

**Important Considerations:**
- SSH key generation needed BEFORE Script 01
- Keep existing SSH session open during SSH hardening (safety)
- Docker daemon restart needed for daemon.json changes (Script 03)
- Portainer deployment is final step (visual confirmation via web UI)
- Phase B should be executed BEFORE deploying production containers

**Folder Clarity:**
- `vm100ugreen` = UGREEN Proxmox, Docker hardening (THIS SESSION)
- `vm100homelab` = Homelab Proxmox, different purposes (future)

---

Session saved. Ready to start Phase A execution when you return.
