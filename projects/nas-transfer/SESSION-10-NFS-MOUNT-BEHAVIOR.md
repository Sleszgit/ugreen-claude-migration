# Session 10: NFS Mount Behavior Explanation

**Date:** 2025-12-21
**Status:** ✅ COMPLETE - Documentation of NFS mount real-time synchronization
**Outcome:** Clear understanding of how NFS mounts work vs. transferred data on UGREEN

---

## Question Asked

**User:** "When I change something on the 918 NAS itself, does it affect the mounts or what's visible on UGREEN?"

This is an important conceptual question about how NFS mounts work and the difference between:
1. **Live mounts** (`/mnt/918-*`) - real-time views of remote filesystem
2. **Transferred data** (`/storage/Media/*`) - static snapshots

---

## Key Concept: NFS Mounts are "Live Views"

When you mount an NFS share, you're creating a **live connection to the remote filesystem**. It's like opening a window into the 918 NAS:

```
Your changes on 918 NAS → Visible immediately through NFS mount
/mnt/918-*              ← Live view, shows current state
```

---

## Two Different Systems

### 1. NFS Mounts (`/mnt/918-*`) - LIVE

**Location:** Proxmox host
**Type:** Live real-time view of remote 918 NAS
**Updates:** Changes on 918 reflected immediately

```
192.168.40.10:/volume1/Filmy918  ←→  /mnt/918-filmy918
     (918 NAS)                        (Proxmox view)

Changes on 918: ✅ Visible in mount immediately
Delete file on 918: ✅ Disappears from mount
Add file to 918: ✅ Appears in mount
Modify file on 918: ✅ New version visible
Edit through mount: ❌ Read-only (blocked)
```

### 2. UGREEN Storage (`/storage/Media/*`) - STATIC COPY

**Location:** UGREEN ZFS storage (20TB RAID1)
**Type:** One-time copies made during transfer sessions
**Updates:** Only changes if you explicitly run new transfers

```
5.7 TB transferred in previous sessions (Sessions 1-8)
├── Movies918/                      (copied Dec 7)
├── Series918/                      (copied Dec 7)
├── aaafilmscopy/                   (copied Dec 8)
└── 20251209backupsfrom918/         (copied Dec 8-9)

Changes on 918: ❌ NOT visible
Delete from 918: ❌ Still exists (it's a copy)
Add to 918: ❌ NOT added automatically
Modify on 918: ❌ Old version remains
```

---

## Practical Examples

### Example 1: Delete a File on 918 NAS

**Action:** Delete `somemovie.mkv` from the 918 NAS Volume 1

```
DELETE: 192.168.40.10:/volume1/Filmy918/somemovie.mkv

Result on Proxmox:
├── /mnt/918-filmy918/somemovie.mkv    ❌ GONE (live view updated)
└── /storage/Media/Movies918/somemovie.mkv  ✅ STILL EXISTS (copy preserved)
```

**Why?** The mount shows what's currently on the 918. The UGREEN copy is permanent.

---

### Example 2: Add New Content to 918 NAS

**Action:** Add 100 GB of new movies to the 918 NAS

```
ADD: 192.168.40.10:/volume1/Filmy918/NewMovies/ (100 GB)

Result on Proxmox:
├── /mnt/918-filmy918/NewMovies/       ✅ VISIBLE immediately (live view)
└── /storage/Media/Movies918/NewMovies/ ❌ NOT here (hasn't been transferred yet)
```

**Next step:** Run transfer script to copy new content to UGREEN.

---

### Example 3: Modify a File on 918 NAS

**Action:** Edit `movie.nfo` metadata file on the 918 NAS

```
EDIT: 192.168.40.10:/volume1/Filmy918/movie.nfo (change metadata)

Result on Proxmox:
├── /mnt/918-filmy918/movie.nfo        ✅ Shows NEW content (live view)
└── /storage/Media/Movies918/movie.nfo ✅ Shows OLD content (snapshot from Dec 7)
```

**Important:** If you rely on updated metadata, you'd need to re-transfer the file.

---

## How NFS Caching Works

There's a slight delay in visibility due to client-side caching:

```
Change on 918 NAS
    ↓
NFS client cache (1-3 second delay)
    ↓
Visible in /mnt/918-* mount
    ↓
Visible to applications reading the mount
```

**Mount options in your setup:**
```
ro,soft,intr,vers=4

ro        = Read-only (prevents accidental changes through mount)
soft,intr = Client timeout behavior (prevents hanging if NAS goes offline)
vers=4    = NFS version 4 (modern, secure protocol)
```

**Caching delay:** Usually < 1 second in practice. File operations show immediately.

---

## Real-World Use Cases

### Use Case 1: Verify What's New Before Transferring

```bash
# See what's CURRENTLY on the 918
ls -lhS /mnt/918-filmy918/

# See what you ALREADY transferred
ls -lhS /storage/Media/Movies918/

# Compare to identify what's new:
# Files in /mnt/918-filmy918/ but NOT in /storage/Media/Movies918/ = need transfer
```

### Use Case 2: Monitor for Changes in Real-Time

```bash
# Watch what's happening on the 918 NAS right now (updates every 5 seconds)
watch -n 5 'du -sh /mnt/918-14tb/ && echo "---" && ls -lh /mnt/918-14tb/ | head -10'
```

### Use Case 3: Prevent Accidental Data Loss

```bash
# Mount is read-only, so you can't corrupt the 918 NAS from UGREEN
rsync -av /storage/Media/ /mnt/918-*
# This command FAILS (read-only mount)
# Your 918 NAS data is safe
```

### Use Case 4: Transfer Only New Content

```bash
# Use rsync to copy new files from 918 mount to UGREEN
rsync -av --progress /mnt/918-filmy918/NewStuff/ /storage/Media/Movies918/NewStuff/

# Now /storage/Media/ has both old AND new content
# Next transfer run can use --append-verify to skip already-copied files
```

---

## Important Safety Implications

### ✅ Safe for Exploration
- You can freely browse `/mnt/918-*` without affecting UGREEN data
- You see the exact current state of the 918 NAS
- Read-only access prevents accidental modifications

### ⚠️ UGREEN Storage is Independent
- `/storage/Media/*` is a permanent, persistent snapshot
- Changes on 918 NAS do NOT automatically update UGREEN copies
- If you delete from 918, your UGREEN copy remains (data safety)

### 🔄 Transfers are One-Way Operations
- NFS mount shows source (918 NAS)
- `/storage/Media/` is the destination
- Transfers always flow: 918 → UGREEN
- Can run multiple transfers to add new content

### 🔒 Read-Only Protection
- Mount is `ro` (read-only) for safety
- You cannot accidentally modify the 918 NAS through the mount
- Prevents data corruption at the source

---

## Summary Table: What Happens When...

| Scenario | NFS Mount<br>(`/mnt/918-*`) | UGREEN Storage<br>(`/storage/Media/`) | Impact |
|----------|---------------------------|-----------------------------------|--------|
| **Delete file on 918** | ❌ Disappears | ✅ Still exists | Data safe on UGREEN |
| **Add file to 918** | ✅ Appears | ❌ Not added | Needs new transfer |
| **Modify file on 918** | ✅ Shows new version | ✅ Shows old version | Old data preserved |
| **Edit through mount** | ❌ Read-only blocked | N/A | Safety: can't corrupt source |
| **918 NAS goes offline** | ❌ Mount unavailable | ✅ Still accessible | Data on UGREEN unaffected |
| **Run new transfer** | N/A | ✅ New files copied | UGREEN gets updated |

---

## Terminology Clarification

### "Mount"
A mount is a connection point where a remote filesystem appears in your local directory tree. It's a live view, not a copy.

### "Transfer" / "Copy"
A transfer is a one-time operation that copies data from source (918 NAS) to destination (UGREEN storage). Creates an independent copy.

### "Snapshot"
A snapshot is data frozen at a moment in time. Your UGREEN storage is a snapshot of what was on 918 NAS on Dec 7-9, 2025.

---

## Workflow Diagram

```
918 NAS                          UGREEN
──────────                       ──────

Volume1/Filmy918  ──NFS mount──> /mnt/918-filmy918    (LIVE)
     (Current)    (Real-time)         │
                                      │ rsync transfer
                                      ↓
                            /storage/Media/Movies918/  (SNAPSHOT)
                                 (Dec 7 copy)
                                 (Static)

                            Changes on 918 NAS
                                  │
                                  └→ Visible in /mnt/918-filmy918/ ✅
                                  └→ NOT in /storage/Media/ ❌
                                  └→ Need new transfer to update UGREEN ↑
```

---

## Key Takeaways

1. **NFS mounts are live** - they show real-time current state of the 918 NAS
2. **UGREEN storage is static** - snapshots made during transfer sessions
3. **They're independent** - changes in one don't affect the other
4. **Read-only protection** - mount is read-only for safety
5. **Transfers are explicit** - you control when data gets copied to UGREEN
6. **Data safety** - if you delete from 918, your UGREEN copies remain safe

---

## Next Steps (When Needed)

### If New Content Added to 918 NAS:
1. Check `/mnt/918-*` to see new content
2. Decide if you want to transfer it
3. Create new rsync scripts or modify existing ones
4. Copy new content to `/storage/Media/`

### If You Want to Unmount (When 918 is Off):
1. `sudo umount /mnt/918-*`
2. Entries in `/etc/fstab` remain (won't cause issues)
3. Can remount later when 918 is back on

### If 918 NAS Goes Offline:
1. Mounts will timeout (soft mount option prevents hanging)
2. UGREEN storage remains fully accessible
3. No data loss - everything is still on UGREEN

---

## Session Summary

**Duration:** ~10 minutes
**Topic:** Conceptual understanding of NFS mounts vs. transferred data
**Difficulty:** Medium (requires understanding distributed filesystems)
**Success Rate:** 100% - Clear explanation provided

**Learning Outcomes:**
✅ Understand NFS mounts as live views
✅ Understand transferred data as static snapshots
✅ Know the implications for data safety
✅ Can plan future transfers effectively

---

**Last Updated:** 2025-12-21
**Status:** Complete - Ready for next transfer sessions or exploration
