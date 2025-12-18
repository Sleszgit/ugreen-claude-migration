# ASRock Z790 Steel Legend WiFi - BIOS Configuration Guide
## i7-14700KF Thermal Management

**Target:** Fix 100-105°C gaming temperatures → 70-85°C
**System:** i7-14700KF + Corsair H150i ELITE LCD XT
**Date:** 12.12.2025

---

## ⚠️ ROOT CAUSE: Power Limits Keep Reverting

### The Problem
Your BIOS power limit settings (PL1/PL2) keep reverting to high values (likely 253W) no matter how many times you change them.

### The Fix
**There is ONE setting causing this:** **"Load Intel Base Power Limit Settings"**

**Location:** OC Tweaker → CPU Configuration → Load Intel Base Power Limit Settings

**Current State (causing problem):** [Enabled]
**Required State:** **[Disabled]**

**What it does when ENABLED:**
- Overrides ALL your manual PL1/PL2 settings
- Forces Intel default base power limits (253W)
- Makes custom power limits impossible to apply
- This is why your settings keep "reverting"

**Solution:** **Disable this setting FIRST before changing power limits!**

---

## EXACT BIOS Menu Locations - ASRock Z790 Steel Legend WiFi

### Method 1: BIOS Undervolting (RECOMMENDED)

**Path:** OC Tweaker → Voltage Configuration → CPU Core/Cache Voltage

**Steps:**
1. Boot into BIOS (Press **F2** or **DEL** during startup)
2. Press **F6** to enter Advanced Mode (if in EZ Mode)
3. Navigate to: **OC Tweaker**
4. Select: **Voltage Configuration**
5. Find: **CPU Core/Cache Voltage**
6. Change mode to: **Offset Mode**
7. Set offset: **-0.050V** (start conservative)
8. Press **F10** → Save & Exit

**Available Modes:**
- **Fixed Mode:** 0.800V to 2.200V (not recommended)
- **Offset Mode:** -0.100V to +0.300V (use this for undervolting)

**Recommended Starting Values:**
- Start: **-0.050V** (-50mV)
- Test stability in gaming for 1-2 hours
- If stable, increase to: **-0.075V**
- If stable, increase to: **-0.100V**
- Max safe typical: **-0.080V to -0.125V** (silicon lottery)
- If unstable: back off by 0.025V

**Expected Results:**
- Temperature drop: 10-20°C
- Power reduction: 20-40W
- Same or better performance (no throttling)

---

### Method 2: Power Limits (CRITICAL FIX)

**Path:** OC Tweaker → CPU Configuration

**CRITICAL: Follow this exact order!**

#### Step 1: DISABLE the protection setting first
1. Navigate to: **OC Tweaker → CPU Configuration**
2. Scroll down to: **Load Intel Base Power Limit Settings**
3. **Change from [Enabled] to [Disabled]**
4. **Do NOT save yet!**

#### Step 2: Set power limits (in same menu)
5. Find: **Long Duration Power Limit (PL1)**
   - Current: 253W (Intel default)
   - Change to: **180W** or **200W**

6. Find: **Short Duration Power Limit (PL2)**
   - Current: 253W (Intel default)
   - Change to: **220W** or **240W**

7. Find: **Package Power Limit3 Time Window (PL3)**
   - Change to: **240W** (optional)

8. Find: **Package Power Limit3 Time Window**
   - Default: 0.00244ms (very short burst)
   - Leave as default or increase slightly

#### Step 3: Save settings
9. Press **F10** → **Save Changes and Exit**
10. Boot into Windows

#### Step 4: Verify settings persisted
11. Open **HWiNFO64** → Sensors
12. Look for: **Package Power (W)**
13. Under gaming load, should stay around 180-220W (not 253W)
14. If it shows 253W → settings reverted → "Load Intel Base Power Limit Settings" still enabled

---

### Additional Critical Settings (Same Menu)

**Path:** OC Tweaker → CPU Configuration

**These should already be correct (you fixed idle temps), but verify:**

1. **Intel SpeedStep Technology** = [Enabled]
2. **C-States** = [Enabled]
   - C1E Support = [Enabled]
   - C3 State Support = [Enabled]
   - C6/C7 State Support = [Enabled]
   - C8 State Support = [Enabled]

3. **CPU Cooler Type** = Select **360mm AIO** or **Water Cooling**
   - This may unlock higher power limits
   - ASRock adjusts power limits based on cooler type

4. **UnderVolt Protection** = [Disabled] (if doing BIOS undervolting)
   - Only needed if XTU/ThrottleStop undervolting doesn't work

---

### Voltage Configuration Additional Settings

**Path:** OC Tweaker → Voltage Configuration

**Optional (for better stability with undervolting):**

1. **CPU Core/Cache Load-Line Calibration** = **Level 3**
   - Reduces voltage droop under load
   - Improves stability with lower voltages

2. **CPU Vcore Compensation** = **Auto** or **Medium**
   - Enhances stability at lower voltages

---

### FIVR Configuration (Advanced)

**Path:** OC Tweaker → FIVR Configuration

**Only adjust if doing deep undervolting (>-0.100V):**

1. **Ring Voltage Mode** = **Override**
2. **Ring Voltage** = 1.08V to 1.28V (adjust based on CPU behavior)
   - Lower for better thermals
   - Higher for stability with aggressive undervolts

**Note:** Most users don't need to touch FIVR settings for basic undervolting.

---

## Alternative: EZ Mode Power Limit Button

**Path:** EZ Mode (F6 to toggle from Advanced Mode)

ASRock has a button labeled: **"Set Intel Power Limits"**

**What it does:**
- Sets PL1 = 125W
- Sets PL2 = 253W

**Problem:** Still uses Intel defaults (253W is too high)

**Not recommended** - use manual settings instead

---

## Why Settings Keep Reverting (SOLVED)

### Root Causes:

1. **"Load Intel Base Power Limit Settings" = Enabled** ← **PRIMARY CAUSE**
   - This setting OVERRIDES all manual power limits
   - Added in BIOS v6.03+ specifically to fix power limit issues
   - Must be **DISABLED** for manual limits to work

2. **Windows Fast Startup**
   - Can cause BIOS to not fully initialize
   - Disable in Windows: Power Options → Choose what power buttons do → Disable "Turn on fast startup"

3. **CPU Cooler Type Setting**
   - ASRock auto-adjusts power limits based on cooler selection
   - If set to "Air Cooling" → conservative limits
   - Change to "360mm AIO" or "Water Cooling"

4. **BIOS Profile Not Saved**
   - Use "Save to Profile" feature (F11 in Advanced Mode)
   - Save your working config as "Profile 1"
   - Can restore if settings change

---

## Recommended BIOS Configuration

### For 100°C Gaming → 80°C Target

**Combine both methods for best results:**

1. **Disable "Load Intel Base Power Limit Settings"**
2. **Set PL1 = 180W, PL2 = 220W**
3. **Set CPU Voltage Offset = -0.075V** (start at -0.050V, test, then increase)
4. **CPU Cooler Type = 360mm AIO or Water Cooling**
5. **C-States = All Enabled** (already done)
6. **SpeedStep = Enabled** (already done)

**Expected Results:**
- **Idle:** 47-50°C (already achieved ✅)
- **Gaming:** 70-85°C (currently 100-105°C)
- **Power:** 180-220W (currently 250W+)
- **Throttling:** None (currently constant throttling)

---

## Testing Protocol

### After Changing BIOS Settings:

1. **Save and Exit BIOS (F10)**

2. **Boot into Windows**

3. **Open HWiNFO64** → Sensors Only
   - Monitor: CPU Package Temp
   - Monitor: CPU Package Power
   - Monitor: Core Voltages
   - Monitor: Thermal Throttling (should show "No")

4. **Open Corsair iCUE**
   - Verify pump speed: ~2,400 RPM
   - Check coolant temp (if available)
   - Verify fans ramping up under load

5. **Idle Test (5 minutes)**
   - Expected: 47-50°C (already working ✅)
   - If higher: C-States not working

6. **Gaming Test (30-60 minutes)**
   - Play Call of Duty
   - Watch HWiNFO64 temps in real-time
   - **Target:** 70-85°C
   - **Acceptable:** Up to 90°C
   - **Problem:** 95°C+
   - **Critical:** 100°C+

7. **Check for Throttling**
   - HWiNFO64 → "Thermal Throttling" sensor
   - Should show "No" during entire gaming session
   - If "Yes" → settings didn't apply or need more aggressive undervolt

8. **Verify Power Limits Applied**
   - HWiNFO64 → CPU Package Power
   - Should stay around 180-220W under gaming
   - If hitting 250W+ → settings reverted → check "Load Intel Base Power Limit Settings" again

---

## Stability Testing

### If System Crashes/Freezes After Undervolting:

**Symptoms of too aggressive undervolt:**
- Blue screen during gaming
- System freeze
- Sudden reboot
- Application crashes
- Artifacts in games

**Fix:**
1. Boot into BIOS
2. Reduce voltage offset by 0.025V
   - If was -0.100V → change to -0.075V
   - If was -0.075V → change to -0.050V
3. Test again

**Safe Conservative Values (99% stable):**
- **-0.050V:** Almost always stable
- **-0.075V:** Usually stable
- **-0.100V:** May require testing
- **-0.125V:** Silicon lottery (some CPUs handle it, some don't)

---

## Verification Commands (Windows)

**Check if settings applied:**

### Method 1: HWiNFO64 (Best)
- Download: https://www.hwinfo.com/
- Run → Sensors Only
- Find: "CPU Package Power"
- Should not exceed your PL2 limit (220W)

### Method 2: Intel XTU (If installed)
- Shows: PL1, PL2, current power draw
- Shows: Current voltage offset
- Shows: Thermal throttling status

### Method 3: ThrottleStop (Alternative)
- Shows: Power limits, temps, throttling
- Can also undervolt from Windows (but BIOS is better)

---

## Emergency: If System Won't Boot

### Clear CMOS (Reset BIOS):

**Method 1: Jumper (Safest)**
1. Power off system, unplug power cable
2. Locate CMOS Clear jumper on motherboard (near battery)
   - **ASRock Z790 Steel Legend WiFi:** Usually labeled "CLRMOS1" or "JBAT1"
3. Move jumper from pins 1-2 to pins 2-3
4. Wait 10 seconds
5. Move jumper back to pins 1-2
6. Plug in power, boot system

**Method 2: Battery (Alternative)**
1. Power off, unplug power cable
2. Remove CMOS battery (coin cell, usually CR2032)
3. Wait 5 minutes
4. Replace battery
5. Boot system

**Method 3: BIOS Button (Easiest if available)**
- Some boards have physical "BIOS Flashback" or "CMOS Clear" button on I/O panel
- Check motherboard manual for location

---

## BIOS Profile Management

### Save Working Configuration:

1. In BIOS, press **F11** → **Save to Profile**
2. Select: **Profile 1**
3. Name it: "Undervolted_180W_PL1" or similar
4. Press **F10** → Save & Exit

### Restore if Settings Change:

1. Boot into BIOS
2. Press **F11** → **Load from Profile**
3. Select: **Profile 1**
4. Press **F10** → Save & Exit

---

## Additional Troubleshooting

### If Power Limits Still Revert:

1. **Update BIOS to latest version**
   - Current: v21.02 (October 2025)
   - Check ASRock website for newer versions
   - Newer BIOS may fix persistence bugs

2. **Disable Windows Fast Startup**
   - Control Panel → Power Options
   - Choose what power buttons do
   - Change settings that are currently unavailable
   - Uncheck "Turn on fast startup (recommended)"
   - Restart

3. **Check for Razer Synapse or other RGB software**
   - Some RGB software can override BIOS settings
   - You already identified Razer Synapse as problematic
   - Uninstall or disable

4. **CMOS Battery Health**
   - If battery is dying, BIOS settings may not persist
   - Replace CR2032 battery if system is 3+ years old

5. **Multi-Core Enhancement (MCE)**
   - Some boards have this setting
   - Can override power limits
   - Set to **Disabled** or **Auto**

---

## Expected Performance Impact

### Before (Current State):
- **Idle Temp:** 47-50°C ✅ (already fixed)
- **Gaming Temp:** 100-105°C ❌
- **Gaming Power:** ~250W
- **Throttling:** Constant
- **Performance:** Degraded (due to throttling)

### After (Target State):
- **Idle Temp:** 47-50°C ✅
- **Gaming Temp:** 70-85°C ✅
- **Gaming Power:** 180-220W
- **Throttling:** None
- **Performance:** Same or better (no throttling = consistent clocks)

### Performance Loss from Power Limits:
- **Minimal:** 2-5% in gaming (not noticeable)
- **Benefit:** 15-35°C cooler, no throttling
- **Net Result:** Better gaming performance (no throttle drops)

### Performance Loss from Undervolting:
- **None:** 0% performance loss (voltage doesn't affect speed)
- **Benefit:** 10-20°C cooler, 20-40W less power
- **Risk:** Zero (cannot damage hardware)

---

## Key Takeaways

1. **"Load Intel Base Power Limit Settings" MUST be [Disabled]**
   - This is why your settings keep reverting
   - DISABLE THIS FIRST before setting power limits

2. **Undervolting is safe and effective**
   - Start at -0.050V
   - Test stability
   - Gradually increase to -0.075V or -0.100V
   - Cannot damage hardware (worst case: system reboots)

3. **Power limits + undervolting = best results**
   - Combine both methods
   - PL1: 180W, PL2: 220W
   - Voltage offset: -0.075V
   - Expected: 70-85°C gaming temps

4. **Your H150i AIO is NOT the problem**
   - It's a premium 360mm AIO
   - Can easily handle 253W
   - Problem is excessive power draw (250W+)
   - Solution is power limits, not cooling

5. **Save BIOS profile after finding stable settings**
   - Easy to restore if something changes
   - F11 → Save to Profile 1

---

## Next Steps - Action Plan

1. **Boot into BIOS (F2 or DEL)**
2. **Navigate to: OC Tweaker → CPU Configuration**
3. **Find: "Load Intel Base Power Limit Settings"**
4. **Change to: [Disabled]** ← **MOST IMPORTANT!**
5. **Set PL1 = 180W**
6. **Set PL2 = 220W**
7. **Navigate to: OC Tweaker → Voltage Configuration**
8. **Set CPU Core/Cache Voltage = Offset Mode: -0.050V**
9. **F11 → Save to Profile 1**
10. **F10 → Save & Exit**
11. **Boot Windows → Open HWiNFO64 + iCUE**
12. **Play Call of Duty for 1 hour**
13. **Report back with temps!**

---

## Documentation Sources

- [ASRock Z790 BIOS Setup Guide (Official)](https://download.asrock.com/Manual/Software/Intel%20Z790/Software_BIOS%20Setup%20Guide_English.pdf)
- [ASRock Z790 Steel Legend WiFi Manual](https://download.asrock.com/Manual/Z790 Steel Legend WiFi.pdf)
- [OC Inside Review - Z790 Steel Legend WiFi BIOS](https://www.ocinside.de/review/mainboard_asrock_z790_steel_legend_wifi/4/)
- [Overclock.net - Undervolting 13700KF Guide](https://www.overclock.net/threads/guideline-undervolting-13700kf-asrock-z790m-38-power-usage-5-performance.1811143/)
- [Overclock.net - ASRock Core Offset Voltages](https://www.overclock.net/threads/asrock-z690-or-z790-where-to-find-core-offset-voltages-in-bios-help.1806791/)

---

**Created:** 12.12.2025
**For:** ASRock Z790 Steel Legend WiFi + i7-14700KF
**Goal:** Fix 100°C gaming temps → 70-85°C
**Method:** Disable "Load Intel Base Power Limit Settings" + Power Limits + Undervolting
