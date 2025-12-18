# Auto-Update System - Setup Complete! 🎉

## What Was Created

### 1. **Auto-Update Script** (`~/scripts/auto-update/.auto-update.sh`)
A smart update script that runs once per day on login. It:
- ✅ Updates Claude Code to the latest version
- ✅ Updates system packages (apt update & upgrade)
- ✅ Cleans up unused packages (autoremove)
- ✅ Logs everything to `~/logs/.auto-update.log`
- ✅ Shows colorful progress output
- ✅ Runs only once per day (won't spam you)
- ✅ Uses lock files to prevent multiple simultaneous runs

### 2. **Sudoers Configuration** (`/tmp/auto-update-sudoers`)
Allows specific update commands to run without password prompts.

### 3. **Installer Script** (`~/scripts/auto-update/install-auto-update-sudo.sh`)
One-time setup script to enable passwordless updates.

---

## 🚀 Quick Start (Required Setup)

**You need to run this ONCE to enable automatic updates:**

```bash
./install-auto-update-sudo.sh
```

This will:
1. Ask for your sudo password (one time only)
2. Configure passwordless sudo for update commands
3. Verify the installation

**After this, updates will run automatically on each login!**

---

## 📋 How It Works

### Automatic Updates
- Script runs once per day when you log in
- If you log in multiple times in one day, it skips (no spam)
- Updates happen in the background with visual progress
- Full logs saved to `~/logs/.auto-update.log`

### Manual Updates
You can always run updates manually:
```bash
~/scripts/auto-update/.auto-update.sh
```

### Check the Log
```bash
cat ~/logs/.auto-update.log          # View full log
tail -50 ~/logs/.auto-update.log     # View last 50 lines
```

---

## 🔒 Security

**Is this safe?**

YES! The sudoers configuration ONLY allows these specific commands:
- `npm update -g @anthropic-ai/claude-code`
- `apt update`
- `apt upgrade -y`
- `apt autoremove -y`

Nothing else. Your system stays secure.

---

## 🛠️ Customization

### Change Update Frequency
Edit `~/scripts/auto-update/.auto-update.sh` and modify the `should_run()` function.
Currently set to once per day.

### Disable Auto-Updates
Remove these lines from `~/.bashrc`:
```bash
# Run auto-update script on login (once per day)
if [ -f "$HOME/.auto-update.sh" ]; then
    "$HOME/.auto-update.sh"
fi
```

### Update Specific Packages Only
Edit `~/scripts/auto-update/.auto-update.sh` and comment out sections you don't want.

---

## 📊 What You'll See

On login (once per day), you'll see:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Auto-Update Starting...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Updating Claude Code...
   Current version: 2.0.60
   ✓ Claude Code is up to date (2.0.60)

📦 Updating system packages...
   ✓ Package list updated
   ✓ All packages are up to date
   ✓ Removed unused packages

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Auto-Update Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Full log: /home/sleszugreen/logs/.auto-update.log
```

---

## 🐛 Troubleshooting

### "Password required for sudo"
Run the installer: `./install-auto-update-sudo.sh`

### Updates not running automatically
Check if script is in `.bashrc`:
```bash
grep auto-update ~/.bashrc
```

### Script running too often
Check the last run file:
```bash
cat ~/.auto-update.lastrun
```
Delete it to force a run: `rm ~/.auto-update.lastrun`

### Check if everything is configured
```bash
ls -la ~/scripts/auto-update/.auto-update.sh   # Should exist and be executable
ls -la /etc/sudoers.d/auto-update              # Should exist (after running installer)
```

---

## 📂 Files Created

| File | Purpose |
|------|---------|
| `~/scripts/auto-update/.auto-update.sh` | Main update script |
| `~/logs/.auto-update.log` | Update history log |
| `~/.auto-update.lastrun` | Tracks last run date |
| `~/.auto-update.lock` | Prevents concurrent runs |
| `/etc/sudoers.d/auto-update` | Passwordless sudo config |
| `~/scripts/auto-update/install-auto-update-sudo.sh` | One-time installer |
| `~/scripts/auto-update/AUTO-UPDATE-README.md` | This file! |

---

## ✅ Next Steps

1. **Run the installer:**
   ```bash
   ~/scripts/auto-update/install-auto-update-sudo.sh
   ```

2. **Test it manually:**
   ```bash
   ~/scripts/auto-update/.auto-update.sh
   ```

3. **Log out and log back in** to see it run automatically!

4. **(Optional) Check the log:**
   ```bash
   cat ~/logs/.auto-update.log
   ```

---

**That's it! Your system will now stay up to date automatically.** 🚀
