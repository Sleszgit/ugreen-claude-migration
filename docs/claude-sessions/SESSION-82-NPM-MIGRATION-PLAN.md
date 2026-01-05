# Nginx Proxy Manager - Migration & Backup Plan

**Status:** 🚨 CRITICAL - NPM is on FAILING VOLUME (volume2/md3)

---

## NPM Location & Risk Assessment

**Current Installation:**
- **Location:** `/volume2/docker/npm/` (on FAILING volume2/md3)
- **Managed By:** Portainer Stack 5
- **Config File:** `/volume2/docker/portainer/data/compose/5/v1/docker-compose.yml`
- **Status:** Inactive (not currently running)
- **Risk:** ⚠️ HIGH - On same failing drive as FILMY920

---

## NPM Docker Compose Configuration

```yaml
version: '3.8'
services:
  nginx-proxy-manager:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '8082:80'
      - '4444:443'
      - '82:81'
    volumes:
      - npm_data:/data
      - npm_ssl:/etc/letsencrypt
    networks:
      - npm_network

volumes:
  npm_data:
  npm_ssl:

networks:
  npm_network:
```

**Critical Details:**
- **Ports Used:** 80→8082, 443→4444, 81→82
- **Data Volume:** npm_data (mounted at /data)
- **SSL/Certs:** npm_ssl (mounted at /etc/letsencrypt)
- **Network:** npm_network (custom bridge)

---

## Migration Options

### Option A: RECOMMENDED - Quick Backup + Export
**Best for immediate data preservation**

1. **Backup Portainer Stack 5 compose file:**
   ```bash
   scp backup-user@192.168.40.20:/volume2/docker/portainer/data/compose/5/v1/docker-compose.yml \
       ~/backups/npm-compose-stack5.yml
   ```

2. **Backup Portainer Stack 5 complete directory:**
   ```bash
   ssh backup-user@192.168.40.20 "tar -czf /tmp/npm-stack5-backup.tar.gz \
       /volume2/docker/portainer/data/compose/5/"

   scp backup-user@192.168.40.20:/tmp/npm-stack5-backup.tar.gz ~/backups/
   ```

3. **Export NPM database (if accessible):**
   - Database typically stored in Docker volume `npm_data`
   - Contains: proxy hosts config, SSL certs, users, authentication
   - Alternative: Use NPM UI export feature (if running)

4. **Result:** You have complete NPM config to recreate it elsewhere

---

### Option B: Full Migration to Homelab
**More complex but preserves running service**

**Prerequisites:**
- Docker + Docker Compose installed on Homelab
- Network access configured
- Storage for NPM volumes

**Steps:**
1. Stop NPM on 920 NAS
2. Backup volumes (using Option A)
3. Redeploy on Homelab using same compose file
4. Reconfigure ports if needed (to avoid conflicts)
5. Restore volumes if needed
6. Update DNS/network to point to Homelab NPM

---

### Option C: Hybrid - Backup + Keep for Now
**Safest approach**

1. **Immediately:** Backup complete Portainer Stack 5 directory
2. **Keep NPM running** on 920 NAS during phase 1 (data evacuation)
3. **After FILMY920 moved:** Migrate NPM to Homelab
4. **Then:** Decommission 920 NAS

---

## Critical Files to Backup

| File/Path | Purpose | Priority |
|-----------|---------|----------|
| `/volume2/docker/portainer/data/compose/5/v1/docker-compose.yml` | NPM service definition | 🔴 CRITICAL |
| `/volume2/docker/portainer/data/compose/5/` | Full stack directory | 🔴 CRITICAL |
| `/volume2/docker/npm/data/` | NPM database & config | 🟠 HIGH |
| `/volume2/docker/npm/letsencrypt/` | SSL certificates | 🟠 HIGH |
| `/volume2/docker/portainer/portainer.db` | Portainer config (contains all stacks) | 🟡 MEDIUM |

---

## What NPM Manages

Nginx Proxy Manager is configured to:
- **Port 8082** - HTTP proxy traffic
- **Port 4444** - HTTPS/SSL proxy traffic
- **Port 82** - NPM admin interface (typically 81)

If NPM is currently proxying services, losing it breaks those proxied connections.

---

## Recommended Action Plan

**Immediate (Today):**
```bash
# 1. Backup complete Portainer Stack 5
ssh backup-user@192.168.40.20 "tar -czf /tmp/npm-full-backup.tar.gz \
    /volume2/docker/portainer/data/compose/5/ \
    /volume2/docker/npm/"

# 2. Download to safe location
scp backup-user@192.168.40.20:/tmp/npm-full-backup.tar.gz ~/backups/

# 3. Verify backup
tar -tzf ~/backups/npm-full-backup.tar.gz | head -20
```

**Before Phase 1 Data Migration:**
- Decide: Keep NPM running or migrate now?
- If migrating: Set up new NPM on Homelab first
- If keeping: Ensure it's not storing critical config only on 920 NAS

**During 920 Decommissioning:**
- Migrate NPM to Homelab (if not done earlier)
- Update any DNS/network rules pointing to 920 NAS NPM

---

## NPM on UGREEN?

Check if NPM is already running on UGREEN:
```bash
ssh ugreen-host "docker ps 2>/dev/null | grep -i npm || echo 'NPM not found on UGREEN'"
```

If yes: Decide whether to consolidate or run both instances.

---

## Next Steps

1. ✅ **Backup NPM immediately** (before failing drive deteriorates)
2. **Assess:** Is NPM currently proxying any critical services?
3. **Plan:** Will you migrate to Homelab or UGREEN?
4. **Execute:** Migration before final 920 NAS decommissioning

---

**Status:** Ready for backup execution
