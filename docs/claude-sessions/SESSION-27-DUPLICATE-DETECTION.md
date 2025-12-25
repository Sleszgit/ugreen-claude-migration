# Session 27 - Duplicate Detection Setup (25 Dec 2025)

## Objective
Create scripts to detect duplicate TV show folders between UGREEN backup and Synology 920, to identify which folders can be safely deleted from UGREEN before copying seriale2023 from Synology.

## Work Completed

### 1. SSH Key Authentication to Synology 920
- ✅ Generated ed25519 SSH key pair in container
- ✅ Added public key to backup-user@192.168.40.20
- ✅ Verified SSH key authentication works

### 2. File Duplicate Detection Script
**Location:** `/mnt/lxc102scripts/duplicate-detection.sh` (or `/nvme2tb/lxc102scripts/` from host)

**Purpose:** Compare files >200MB between UGREEN and Synology
- Scans `/storage/Media/20251209backupsfrom918/` (UGREEN)
- Scans `/volume1/Seriale 2023/Seriale 2023/` (Synology 920)
- Compares by filename only
- Also compares folders by name + file count + total size

**Results:**
- UGREEN files > 200MB: 7,347
- Synology files > 200MB: 31,645
- Duplicate files (same filename): 6,755
- Duplicate folders (same name + structure): 0

### 3. Folder Comparison Script (Name-Based)
**Location:** `/mnt/lxc102scripts/folder-comparison.sh` (or `/nvme2tb/lxc102scripts/` from host)

**Purpose:** Identify duplicate folders by name only + UGREEN-only folders
- Compares contents of: `/storage/Media/20251209backupsfrom918/backup seriale 2022 od 2023 09 28`
- Against: `/volume1/Seriale 2023/Seriale 2023` (Synology)
- Lists folders that exist on both systems (duplicates by name)
- Lists folders that exist ONLY on UGREEN (safe to delete)
- Shows folder sizes and total space that can be freed

**To run:**
```bash
sudo bash /nvme2tb/lxc102scripts/folder-comparison.sh
```

## Key Findings

### UGREEN Backup Structure
Path: `/storage/Media/20251209backupsfrom918/`
Contains folders:
- Backup dokumenty z domowego 2023 07 14
- Backup drugie dokumenty z domowego 2023 07 14
- Backup komputera prywatnego 2024 03 06
- Backup pendrive 256 GB 2023 08 23
- **backup seriale 2022 od 2023 09 28** ← Compared with Synology
- Backupy zdjęć Google od 2507
- Backup z DELL XPS 2024 11 01
- Zgrane ze starego dysku 2023 08 31

### SSH Connection Details
- Host: 192.168.40.20 (Synology 920)
- User: backup-user
- Auth: SSH key ed25519
- Key location: `~/.ssh/id_ed25519`

## Transfer Status
Active screen session for Phase 2.5 transfer: `3759907.phase2.5-transfer`
- Monitor with: `screen -r 3759907.phase2.5-transfer`

## Next Steps
1. Run folder-comparison.sh on Proxmox host to identify UGREEN-only folders
2. Based on results, create deletion script for duplicate folders
3. Execute deletion to free up space before copying seriale2023 from Synology

## Scripts Created
- `/mnt/lxc102scripts/duplicate-detection.sh` - File-based duplicate detection
- `/mnt/lxc102scripts/folder-comparison.sh` - Folder name comparison + UGREEN-only identification

Both scripts are accessible from Proxmox host at `/nvme2tb/lxc102scripts/`

---
Generated: 2025-12-25
