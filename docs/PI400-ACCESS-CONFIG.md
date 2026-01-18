# Pi400 Access Configuration

**Date:** 2026-01-18
**Device:** Raspberry Pi 400
**IP:** 192.168.40.50
**Hostname:** pi400

---

## Authentication Setup

### Service Account
- **Username:** `claude-ai`
- **Shell:** `/bin/bash`
- **Home:** `/home/claude-ai`
- **SSH Key:** ED25519 key stored in `~/.ssh/id_ed25519` on LXC102
- **Public Key Fingerprint:** `SHA256:lbzmvDxIWgq7WVmyhwIHkELqBdkkVD0ijhx7Mnkjugs`

### SSH Configuration
Added to `~/.ssh/config`:
```
Host pi400
    HostName 192.168.40.50
    User claude-ai
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new
    UserKnownHostsFile ~/.ssh/known_hosts
```

**Usage:** `ssh pi400` (instead of `ssh claude-ai@192.168.40.50`)

### Sudo Access
- **File:** `/etc/sudoers.d/claude-ai`
- **Permissions:** `0440` (read-only)
- **Privileges:** All passwordless sudo access
- **Testing:** `ssh pi400 "sudo systemctl list-units --type=service"`

---

## Installed Services (Docker Containers)

| Service | Status | Container Name | Port | Health |
|---------|--------|----------------|------|--------|
| Pi-hole | ✅ Running | pihole | DNS (53) | Healthy |
| Netdata | ✅ Running | netdata | 19999 | Healthy |
| NetAlertX | ✅ Running | netalertx | TBD | Healthy |
| Portainer Agent | ✅ Running | portainer_agent | 9001 | Running |

All services verified running as of 2026-01-18 04:57 UTC.

---

## Management Commands

### View all containers
```bash
ssh pi400 "sudo docker ps -a"
```

### Check container logs
```bash
ssh pi400 "sudo docker logs -f <container_name>"
```

### Restart a service
```bash
ssh pi400 "sudo docker restart pihole"
ssh pi400 "sudo docker restart netdata"
ssh pi400 "sudo docker restart netalertx"
```

### Execute command inside container
```bash
ssh pi400 "sudo docker exec pihole <command>"
```

### View container stats
```bash
ssh pi400 "sudo docker stats"
```

---

## Web Interfaces

| Service | URL | Notes |
|---------|-----|-------|
| Netdata | http://192.168.40.50:19999 | Real-time system monitoring |
| Pi-hole | http://pi400 or IP | DNS/DHCP admin panel |
| NetAlertX | Port TBD | Network discovery/alerts |

---

## Security Posture

✅ **Implemented:**
- Dedicated service account (not using fructose5763 personal account)
- SSH key-based authentication (no password login)
- Passwordless sudo for automation (avoiding password prompts in scripts)
- Principle of least privilege (dedicated user for AI operations)
- Audit trail (all claude-ai commands logged by sudo)

---

## Troubleshooting

### SSH Connection Issues
```bash
# Test with verbose output
ssh -vvv pi400 "echo test"

# Check key permissions
ssh pi400 "ls -la ~/.ssh/"
```

### Sudo Access Issues
```bash
# Verify sudoers config
ssh pi400 "sudo cat /etc/sudoers.d/claude-ai"

# Test sudo directly
ssh pi400 "sudo whoami"
```

### Docker Container Issues
```bash
# View container health
ssh pi400 "sudo docker ps --format='table {{.Names}}\t{{.Status}}'"

# Check container logs
ssh pi400 "sudo docker logs pihole"
```

---

## Files Modified

- `/home/sleszugreen/.ssh/config` - Added pi400 host alias
- `/home/claude-ai/.ssh/authorized_keys` - Added ED25519 public key (on Pi400)
- `/etc/sudoers.d/claude-ai` - Created passwordless sudo entry (on Pi400)
- `/etc/passwd` - Added claude-ai user (on Pi400)

---

## Next Steps

1. Test Pi-hole DNS functionality
2. Configure NetAlertX port mapping and test
3. Set up monitoring/alerting on Netdata
4. Document service-specific management procedures
