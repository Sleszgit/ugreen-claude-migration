# CPU Overheating Problem Summary for Claude Code

## System Specifications
- **CPU**: Intel i7-14700KF
- **Motherboard**: ASRock Z790 Pro RS
- **BIOS Version**: 21.02
- **Cooling**: Corsair H150i AIO (360mm)
- **Pump Speed**: ~2,400 RPM (confirmed working)
- **Location**: Poland (Europe/Warsaw timezone)

## Problem Overview
The CPU is experiencing dangerous overheating during gaming, reaching **100-105°C** with **constant thermal throttling** in Call of Duty. Initial idle temperatures were also high at 82°C but were successfully reduced to 47-50°C through previous troubleshooting.

## Previous Successful Fixes (Idle Temperature)
1. **BIOS Configuration**:
   - Enabled C-States (C1E, C3, C6, C7, C8)
   - Enabled Intel SpeedStep
   - Result: Reduced idle from 82°C to 47-50°C (~35-40°C improvement)

2. **Software Issues Identified**:
   - **Razer Synapse** was causing CPU load issues at idle
   - Windows power management settings were adjusted

3. **Hardware Verification**:
   - Thermal paste replacement performed
   - AIO pump confirmed operational

## Current Critical Issues

### Gaming Temperature Problem
- **Temperature**: 100-105°C during Call of Duty
- **Throttling**: Constant thermal throttling
- **Expected Power Draw**: ~250W during gaming
- **Target Temperature**: 80-85°C (no throttling)

### Root Cause Identified: BIOS Settings Mysteriously Resetting

Two critical BIOS protection settings are **BLOCKING** manual configurations:

#### 1. UnderVolt Protection (Currently: ENABLED)
- **Location**: OC Tweaker → CPU Configuration → UnderVolt Protection
- **Current State**: [Enabled] - Blocks OS-level undervolting (Intel XTU, ThrottleStop)
- **Required State**: [Disabled] - Allows both BIOS and OS-level undervolting
- **Page**: 37 in ASRock Z790 BIOS Setup Guide

#### 2. Load Intel Base Power Limit Settings (Currently: ENABLED)
- **Location**: OC Tweaker → CPU Configuration → Load Intel Base Power Limit Settings
- **Current State**: [Enabled] - Forces Intel stock power limits (conservative)
- **Required State**: [Disabled] - Allows custom power limits (180W/220W/240W settings)
- **Page**: 38 in ASRock Z790 BIOS Setup Guide
- **Note**: Added in BIOS version 6.03+ (confirmed present in v21.02)

**BOTH SETTINGS ARE IN THE SAME MENU** where power limits are configured.

## Recommended Solutions

### Solution 1: Undervolting (Primary Recommendation)
**Expected Results**:
- Temperature drop: 10-20°C (from 100°C to 80-85°C)
- Power reduction: 20-40W (from ~250W to 200-220W)
- Eliminate thermal throttling
- Maintain same CPU performance

**Methods**:
1. **Intel XTU (OS-level)**:
   - Start with -0.050V (50mV)
   - Test stability in gaming for 30-60 minutes
   - Gradually increase to -0.075V or -0.100V
   - Typical safe range: -0.080V to -0.125V
   - Back off 0.025V if instability occurs

2. **BIOS Undervolting** (more permanent):
   - OC Tweaker → CPU Configuration → CPU Core Voltage
   - Set to Adaptive or Offset mode
   - Apply negative offset (start with -0.050V)

**Advantages**:
- ✅ Lower temperatures (10-20°C typical)
- ✅ Reduced power consumption
- ✅ Quieter system (fans work less)
- ✅ Longer CPU lifespan
- ✅ No throttling
- ✅ Same or better performance
- ✅ **Completely safe** - cannot damage hardware

**Potential Issues** (minor):
- ⚠️ System instability if too aggressive (just reduce offset)
- ⚠️ Takes time to find optimal value (silicon lottery)
- ⚠️ Settings may reset after Windows/BIOS updates
- ⚠️ NONE risk to hardware (worst case: reboot and adjust)

### Solution 2: Power Limits
- **Target Settings**: PL1: 180W / PL2: 220W / PL3: 240W
- **Current Problem**: Settings keep resetting due to "Load Intel Base Power Limit Settings"
- **Fix**: Disable the protection setting to make limits persistent

### Solution 3: Additional Cooling Optimization
1. **Fan Curves**: Switch from "Balanced" to "Performance" mode
2. **Case Airflow**: Verify H150i radiator has proper ventilation
3. **Pump Verification**: Confirm still running at ~2,400 RPM

## Required BIOS Changes (CRITICAL)

Navigate to: **OC Tweaker → CPU Configuration**

Set the following (all in the same menu):
1. **UnderVolt Protection** = [Disabled]
2. **Load Intel Base Power Limit Settings** = [Disabled]
3. **PL1** = 180W
4. **PL2** = 220W
5. **PL3** = 240W
6. **Core Voltage Offset** = -0.050V (start conservative)

Save with F10 and test.

## Testing Protocol
After making changes:
1. Boot into Windows
2. Monitor with HWiNFO64 or Intel XTU
3. Play Call of Duty for 30-60 minutes
4. Check for:
   - Temperature reduction
   - No thermal throttling
   - System stability (no crashes/freezes)
   - Power consumption reduction

## Expected Final Results
- **Before**: 100°C, throttling, ~250W
- **After**: 80-85°C, no throttling, ~200-220W
- **Performance**: Same or better (no throttling = consistent speeds)

## Documentation Sources
- ASRock Z790 BIOS Setup Guide (Official)
- Previous troubleshooting conversation: https://claude.ai/chat/cf5baca4-656f-457a-978f-577b56060fde

## Next Steps for Claude Code
1. Help verify current BIOS settings
2. Guide through undervolting process
3. Create monitoring scripts for temperature/power tracking
4. Establish stability testing protocols
5. Document final working configuration
6. Set up alerts for thermal issues

## Notes
- The mystery of resetting BIOS settings is explained by the "Load Intel Base Power Limit Settings" option
- Undervolting is the safest and most effective solution for the 100°C gaming problem
- All changes are reversible and cannot damage hardware
- Silicon lottery means each CPU will have different optimal undervolt values
