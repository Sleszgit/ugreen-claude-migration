# Utility Scripts

**Purpose:** One-off utility scripts and helpers that don't belong to specific projects

---

## 📂 Script Categories

### **General Utilities**
- Diagnostic tools
- System helpers
- One-time setup scripts
- Administrative utilities

---

## 📝 Examples of Scripts to Move Here

From home directory:
- `checkpoint-verify.sh` - ZFS checkpoint verification
- `deploy-zfs-auto-import.sh` - ZFS import automation
- `enable-api-access.sh` - API setup helper
- `diagnose-homelab-setup.sh` - Diagnostic tool
- `final-hardening.sh` - Hardening utility
- `fix-zfs-auto-import.sh` - ZFS fix utility
- Similar one-off scripts

---

## 🏷️ Naming Convention

```
[purpose]-[function].sh

Examples:
  zfs-checkpoint-verify.sh
  api-enable-helper.sh
  homelab-diagnostic-tool.sh
  hardening-finalizer.sh
```

---

## 📋 Script Template

Each utility script should have:

```bash
#!/bin/bash

################################################################################
# Script Name: [name]
# Purpose: [Clear one-liner describing what this does]
# Author: Claude Code
# Created: 2026-01-01
# Usage: ./[script-name].sh [options]
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/logs/$(basename "$0" .sh).log"

# Functions
main() {
    # Implementation
    echo "Script execution"
}

# Error handling
trap 'echo "Error: Script failed" >&2; exit 1' ERR

# Execute
main "$@"
```

---

## 📊 Organization

Keep this folder lean:
- One script per file (no bundling)
- Clear, descriptive names
- Related scripts can be grouped in subfolders if needed

Example structure:
```
scripts/utility/
├── README.md (this file)
├── zfs-*.sh                 (ZFS utilities)
├── api-*.sh                 (API helpers)
├── diagnostic-*.sh          (Diagnostic tools)
└── hardening-*.sh           (Security utilities)
```

---

## 🚀 When to Move Script Here

Move one-off scripts from home directory if:
- ✅ Stable and tested
- ✅ Used occasionally (not daily)
- ✅ Not part of a larger project
- ✅ General utility value
- ❌ Active development (keep in project folder)
- ❌ Infrastructure automation (use `scripts/infrastructure/` instead)

---

## 📚 Other Script Folders

If your script fits another category better:

| Folder | Purpose | Example |
|--------|---------|---------|
| `scripts/auto-update/` | Auto-update system | .auto-update.sh |
| `scripts/infrastructure/` | LXC/Proxmox management | fix-lxc-mount.sh |
| `scripts/services/` | Service configuration | samba, ssh setup |
| `scripts/git-utils/` | Git automation | commit helpers |
| `scripts/utility/` | One-off utilities | diagnostics, helpers |
| `ai-projects/` | Collaborative projects | Complex tools |
| `claude-solo/` | Project-based tools | Utilities in tools/ subfolder |

---

## 🔗 Related Documentation
- `ORGANIZATION.md` - Folder structure overview
- `scripts/` - Scripts directory index

---

**Last Updated:** 2026-01-01
