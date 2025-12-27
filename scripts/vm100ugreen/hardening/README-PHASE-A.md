# Phase A: VM 100 UGREEN - Docker Host Hardening

**Status:** Ready for Execution  
**Target VM:** VM 100 (ugreen-docker) - 192.168.40.60  
**Duration:** 1.5-2 hours total  
**Prerequisites:** VM 100 is running, SSH access, passwordless sudo configured

---

## 📋 Quick Reference

**Safe to run during active operations:**
- Script 00: Pre-hardening checks (backup/verify only)
- Script 04: Docker network security (no service restarts)

**Requires downtime or careful monitoring:**
- Script 01: SSH hardening (changes SSH port/auth)
- Script 02: UFW firewall (enables firewall)
- Script 03: Docker daemon hardening (restarts Docker)
- Script 05: Portainer deployment (new container)

---

## 🚀 Execution Steps

### Step 1: Login to VM 100
```bash
ssh sleszdockerugreen@192.168.40.60
# Or use alternative SSH port if already changed
ssh -p 22022 -i ~/.ssh/id_ed25519 sleszdockerugreen@192.168.40.60
```

### Step 2: Create Project Directory
```bash
mkdir -p ~/vm100-hardening/backups
```

### Step 3: Run Scripts in Order

#### Script 00: Pre-Hardening Checks (10 min) - SAFE
**Purpose:** Backup critical files, verify prerequisites  
**Risk:** None - read-only + backups only  
**User Approval:** NO

```bash
bash ~/scripts/vm100ugreen/hardening/00-pre-hardening-checks.sh
```

**Output:** Creates backups in `~/vm100-hardening/backups/`

---

#### Script 01: SSH Hardening (15 min) - REQUIRES APPROVAL
**Purpose:** Change SSH port to 22022, disable password authentication  
**Risk:** HIGH - Can lock you out if not done carefully  
**User Approval:** YES - Must verify key auth before confirming

```bash
bash ~/scripts/vm100ugreen/hardening/01-ssh-hardening.sh
```

**Critical Warnings:**
- ⚠️ **KEEP EXISTING SSH SESSION OPEN** during execution
- You MUST test key authentication BEFORE confirming completion
- Have Proxmox console access ready as backup
- Script will pause for your verification - follow instructions

**After script completes:**
- Test new SSH connection in NEW terminal: `ssh -p 22022 -i ~/.ssh/id_ed25519 sleszdockerugreen@192.168.40.60`
- If key auth works, press ENTER in script terminal
- If key auth fails, do NOT close script terminal (you might get locked out)

---

#### Script 02: UFW Firewall (10 min) - SAFE
**Purpose:** Enable UFW firewall, configure rules  
**Risk:** LOW - Script includes SSH rule, won't lock you out  
**User Approval:** NO

```bash
bash ~/scripts/vm100ugreen/hardening/02-ufw-firewall.sh
```

**Output:** UFW enabled with rules for SSH (22022) and Portainer (9443)

---

#### Script 03: Docker Daemon Hardening (15 min) - REQUIRES APPROVAL
**Purpose:** Harden Docker daemon, enable userns-remap  
**Risk:** MEDIUM - Restarts Docker daemon  
**User Approval:** YES - Confirm Docker restarts successfully

```bash
bash ~/scripts/vm100ugreen/hardening/03-docker-daemon-hardening.sh
```

**Side Effects:**
- Docker daemon restarts (10-30 seconds downtime)
- Any running containers will be restarted
- User namespace remapping may affect existing volumes

**Verification:** Script will confirm Docker is healthy before completing

---

#### Script 04: Docker Network Security (10 min) - SAFE
**Purpose:** Create 3 isolated Docker networks  
**Risk:** NONE - Only creates networks, no service restarts  
**User Approval:** NO

```bash
bash ~/scripts/vm100ugreen/hardening/04-docker-network-security.sh
```

**Output:** Creates networks and `docs/NETWORK-ARCHITECTURE.md`

**Networks created:**
- `frontend` (172.18.0.0/16) - User-facing services
- `backend` (172.19.0.0/16) - Databases and internal APIs
- `monitoring` (172.20.0.0/16) - Logging and observability

---

#### Script 05: Portainer Deployment (10 min) - SAFE
**Purpose:** Deploy Portainer web UI for container management  
**Risk:** LOW - Deploys new container on monitoring network  
**User Approval:** YES - Confirm Portainer web UI is accessible

```bash
bash ~/scripts/vm100ugreen/hardening/05-portainer-deployment.sh
```

**Output:** Portainer running on `https://192.168.40.60:9443`

**First Login:**
1. Open browser: `https://192.168.40.60:9443`
2. Accept self-signed certificate warning
3. Create strong admin password
4. Verify Docker environment is connected
5. Explore Containers, Images, Networks tabs

---

#### Checkpoint Script: Phase A Verification (10 min) - SAFE
**Purpose:** Verify all Phase A measures are in place  
**Risk:** NONE - Read-only verification  
**User Approval:** NO - But review results

```bash
bash ~/scripts/vm100ugreen/hardening/05-checkpoint-phase-a.sh
```

**Output:** `~/vm100-hardening/CHECKPOINT-A-RESULTS.txt`

**Success Criteria:** All 8 tests must PASS
- Test 1: SSH on port 22022 with keys-only auth
- Test 2: Password authentication disabled
- Test 3: UFW firewall active and configured
- Test 4: Docker daemon hardened (userns-remap)
- Test 5: Custom Docker networks exist
- Test 6: Portainer accessible on HTTPS
- Test 7: Docker daemon healthy
- Test 8: Proxmox console access (manual verification)

**If ANY test fails:**
- Do NOT proceed to Phase B
- Fix the failed test using rollback procedures
- Re-run checkpoint script

---

## 📁 Directory Structure

```
~/scripts/vm100ugreen/hardening/
├── 00-pre-hardening-checks.sh      # Step 1: Backup & verify
├── 01-ssh-hardening.sh              # Step 2: SSH security
├── 02-ufw-firewall.sh               # Step 3: Firewall rules
├── 03-docker-daemon-hardening.sh    # Step 4: Docker security
├── 04-docker-network-security.sh    # Step 5: Network isolation
├── 05-portainer-deployment.sh       # Step 6: Web UI
├── 05-checkpoint-phase-a.sh         # Verification: All 8 tests
├── 99-emergency-rollback.sh         # Emergency: Restore backups
├── README-PHASE-A.md                # This file
├── docs/
│   └── NETWORK-ARCHITECTURE.md     # Network design (created by script 04)
└── backups/                         # Config backups (created by script 00)
    ├── sshd_config.backup
    ├── daemon.json.backup
    ├── ufw-status.backup
    └── authorized_keys.backup
```

---

## 🚨 Emergency Procedures

### If Locked Out of SSH

**Option 1: Use Proxmox Console (Easiest)**
1. Access Proxmox Web UI: `https://192.168.40.60:8006`
2. Navigate to VM 100 → Console
3. Login as `sleszdockerugreen`
4. Run rollback: `bash ~/scripts/vm100ugreen/hardening/99-emergency-rollback.sh`

**Option 2: Manual Rollback**
```bash
# From Proxmox console
sudo cp ~/vm100-hardening/backups/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo ufw disable
```

**Option 3: Rollback Script**
```bash
bash ~/scripts/vm100ugreen/hardening/99-emergency-rollback.sh
```

---

## ✅ Success Criteria

Phase A is complete when:
1. ✅ SSH accessible on port 22022 with keys-only authentication
2. ✅ Password authentication disabled
3. ✅ UFW firewall active (protecting SSH and Portainer)
4. ✅ Docker daemon hardened (userns-remap active)
5. ✅ Custom Docker networks created (frontend, backend, monitoring)
6. ✅ Portainer deployed and accessible via web UI
7. ✅ All checkpoint tests pass
8. ✅ Proxmox console emergency access verified

---

## 📝 Useful Commands

### View Phase A Status
```bash
# Check SSH hardening
sudo grep "^Port\|^PasswordAuthentication" /etc/ssh/sshd_config

# Check firewall
sudo ufw status verbose

# Check Docker hardening
docker info | grep -i "userns"

# Check Docker networks
docker network ls | grep -E "(frontend|backend|monitoring)"

# Check Portainer
docker ps | grep portainer
```

### View Backups
```bash
ls -lh ~/vm100-hardening/backups/
```

### View Checkpoint Results
```bash
cat ~/vm100-hardening/CHECKPOINT-A-RESULTS.txt
```

### Emergency Rollback
```bash
bash ~/scripts/vm100ugreen/hardening/99-emergency-rollback.sh
```

---

## 🔗 Related Documentation

- **Network Architecture:** `docs/NETWORK-ARCHITECTURE.md`
- **Full Hardening Plan:** `~/.claude/plans/scalable-stirring-rain.md`
- **Session Notes:** `~/docs/claude-sessions/SESSION-26-VM100UGREEN-HARDENING-PLAN.md`

---

## ⏱️ Timeline Estimate

Assuming no issues:

| Script | Duration | Task |
|--------|----------|------|
| 00 | 10 min | Pre-hardening checks |
| 01 | 15 min | SSH hardening |
| 02 | 10 min | UFW firewall |
| 03 | 15 min | Docker daemon hardening |
| 04 | 10 min | Docker networks |
| 05 | 10 min | Portainer deployment |
| Checkpoint | 10 min | Verification |
| **Total** | **90 min** | 1.5 hours |

**Add 15-30 min if any tests fail and need fixing**

---

## 🎯 Next Steps After Phase A

1. **Verify Portainer Web UI** - Login and explore
2. **Test SSH access** - Confirm port 22022 works
3. **Review checkpoint results** - Ensure all tests passed
4. **Schedule Phase B** - OS & Container hardening (2-2.5 hours)
   - Requires Phase A to be complete
   - Should run BEFORE deploying production containers

---

## 📞 Troubleshooting

### Script fails to run
```bash
# Make scripts executable
chmod +x ~/scripts/vm100ugreen/hardening/*.sh

# Run specific script
bash ~/scripts/vm100ugreen/hardening/00-pre-hardening-checks.sh
```

### Lost SSH access
1. Use Proxmox console (see Emergency Procedures)
2. Run rollback script
3. Restore SSH to default state

### Docker daemon won't restart
1. Check logs: `journalctl -xe | grep docker`
2. Restore daemon.json backup: `sudo cp ~/vm100-hardening/backups/daemon.json.backup /etc/docker/daemon.json`
3. Restart: `sudo systemctl restart docker`

### Portainer not accessible
1. Verify container running: `docker ps | grep portainer`
2. Check logs: `docker logs portainer`
3. Verify network: `docker network ls | grep monitoring`
4. Wait 10-15 seconds for startup

### UFW blocking traffic
Check rules: `sudo ufw status verbose`
Disable if needed: `sudo ufw disable`

---

## 📌 Important Notes

- **Backups are critical** - Script 00 creates them; keep them safe
- **Keep terminal open** - During SSH hardening, don't close terminal
- **Test thoroughly** - Especially SSH key authentication
- **Proxmox console is your safety net** - Know how to access it
- **Docker restart expected** - Script 03 will restart daemon (10-30s)

---

**Last Updated:** $(date)  
**Created for:** VM 100 UGREEN Docker Host  
**Maintenance User:** sleszdockerugreen
