# Proxmox Command Reference

**IMPORTANT:** All commands on this page run on **Proxmox Host ONLY** (hostname: `ugreen`). They are NOT available in LXC 102 container.

---

## pct - Container Management

**pct exec** - Execute command inside container
```bash
sudo pct exec <vmid> -- <command>

Examples:
sudo pct exec 102 -- apt update
sudo pct exec 102 -- npm update -g @anthropic-ai/claude-code
sudo pct exec 102 -- bash -c "echo 'test' > /tmp/file.txt"
```

**pct enter** - Interactive shell in container
```bash
sudo pct enter <vmid>

Example:
sudo pct enter 102
```

**pct push** - Copy file TO container
```bash
sudo pct push <vmid> <source-file> <destination-path>

Example:
sudo pct push 102 /local/file.txt /root/file.txt
```

**pct pull** - Copy file FROM container
```bash
sudo pct pull <vmid> <path> <destination>

Example:
sudo pct pull 102 /var/log/syslog /local/syslog.backup
```

**pct status** - Show container state
```bash
sudo pct status <vmid>

Example:
sudo pct status 102
```

**pct list** - List all containers
```bash
sudo pct list
```

**pct create** - Create new container
```bash
sudo pct create <vmid> <ostemplate> -hostname <name> -memory <mb>

Example:
sudo pct create 103 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst -hostname mycontainer -memory 2048
```

**pct set** - Modify container configuration
```bash
sudo pct set <vmid> -<option> <value>

Examples:
sudo pct set 102 -memory 4096
sudo pct set 102 -onboot 1
sudo pct set 102 -hostname newhostname
```

**pct destroy** - Delete container
```bash
sudo pct destroy <vmid> --purge

Options:
  --purge    Remove all data
  --force    Force destruction
```

**pct clone** - Copy container
```bash
sudo pct clone <vmid> <newid> -hostname <newname>

Example:
sudo pct clone 102 103 -hostname cloned-container
```

---

## qm - Virtual Machine Management

**qm start** - Start VM
```bash
sudo qm start <vmid>

Example:
sudo qm start 100
```

**qm stop** - Forcefully stop VM
```bash
sudo qm stop <vmid>

Example:
sudo qm stop 100
```

**qm shutdown** - Graceful shutdown
```bash
sudo qm shutdown <vmid> --timeout <seconds>

Example:
sudo qm shutdown 100 --timeout 60
```

**qm status** - Show VM status
```bash
sudo qm status <vmid>

Example:
sudo qm status 100
```

**qm list** - List all VMs
```bash
sudo qm list
```

**qm reboot** - Reboot VM
```bash
sudo qm reboot <vmid> --timeout <seconds>

Example:
sudo qm reboot 100 --timeout 60
```

**qm config** - Show VM configuration
```bash
sudo qm config <vmid>

Example:
sudo qm config 100 | grep -E "bios|machine|ide|boot"
```

**qm set** - Modify VM configuration
```bash
sudo qm set <vmid> -<option> <value>

Examples:
sudo qm set 100 -memory 2048
sudo qm set 100 -cores 4
sudo qm set 100 -ide2 none          # Remove IDE device
```

**qm create** - Create new VM
```bash
sudo qm create <vmid> -name <name> -memory <mb> -cores <num>

Example:
sudo qm create 101 -name myvm -memory 2048 -cores 4 -storage local
```

**qm destroy** - Delete VM
```bash
sudo qm destroy <vmid> --purge

Options:
  --purge    Remove all data
  --force    Force destruction
```

---

## pvesh - Proxmox API Shell (Query & Configure)

**pvesh get** - Query API (READ operations)
```bash
sudo pvesh get <path>

Common queries:
sudo pvesh get /nodes                          # List all nodes
sudo pvesh get /nodes/ugreen                   # Node info
sudo pvesh get /nodes/ugreen/lxc               # List containers
sudo pvesh get /nodes/ugreen/qemu              # List VMs
sudo pvesh get /cluster/status                 # Cluster status
sudo pvesh get /nodes/ugreen/qemu/100/status/current  # VM 100 status
```

**pvesh set** - Modify API settings (WRITE operations)
```bash
sudo pvesh set <path> -<key> <value>

Example:
sudo pvesh set /cluster/options -console html5
```

**pvesh usage** - Show endpoint documentation
```bash
sudo pvesh usage <path> -v

Example:
sudo pvesh usage /nodes/ugreen/qemu -v
```

**Output Formats:**
```bash
--output-format json              # JSON (parseable)
--output-format json-pretty       # Pretty JSON
--output-format text              # Plain text
--output-format yaml              # YAML format
```

---

## pveum - User & Permission Management

**pveum user add** - Create new user
```bash
sudo pveum user add <userid>

Example:
sudo pveum user add claude-reader@pam
```

**pveum user token add** - Create API token
```bash
sudo pveum user token add <userid> <tokenid> --expire 0

Example:
sudo pveum user token add claude-reader@pam claude-token --expire 0

Output includes:
  - Token ID: claude-reader@pam!claude-token
  - Token value: (save immediately - only shown once!)
```

**pveum user token delete** - Revoke token
```bash
sudo pveum user token delete <userid> <tokenid>

Example:
sudo pveum user token delete claude-reader@pam claude-token
```

**pveum acl modify** - Assign permissions to users
```bash
sudo pveum acl modify <path> -user <userid> -role <role>

Examples:
sudo pveum acl modify / -user claude-reader@pam -role PVEAuditor    # Read-only cluster access
sudo pveum acl modify /nodes/ugreen -user alice@pam -role PVEAdmin   # Admin on specific node

Available Roles:
  PVEAuditor              Read-only access
  PVEAdmin                Full administrative access
  PVEVMAdmin              VM/Container management only
  PVEPoolAdmin            Pool management
```

**pveum user list** - List all users
```bash
sudo pveum user list
```

---

## System Commands

**pveversion** - Check Proxmox version
```bash
pveversion
```

**Firewall Status**
```bash
sudo systemctl status pve-firewall.service
sudo iptables -L -n
sudo systemctl restart pve-firewall.service    # After config changes
```

---

## Documentation

- [pct Manual](https://pve.proxmox.com/pve-docs/pct.1.html)
- [qm Manual](https://pve.proxmox.com/pve-docs/qm.1.html)
- [pvesh Manual](https://pve.proxmox.com/pve-docs/pvesh.1.html)
- [pveum Manual](https://pve.proxmox.com/pve-docs/pveum.1.html)
- [Proxmox API Docs](https://pve.proxmox.com/wiki/Proxmox_VE_API)
