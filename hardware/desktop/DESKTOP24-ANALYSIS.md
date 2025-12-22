# Desktop Hardware Analysis - DESKTOP24

**Analysis Date:** 12.12.2025
**System Name:** DESKTOP24
**User:** jakub
**Analysis by:** Claude Code Hardware Expert

---

## System Overview

**Class:** High-End Gaming/Workstation Desktop
**Performance Tier:** Enthusiast/Professional
**Primary Use:** Gaming, Content Creation, Professional Workloads

---

## Hardware Specifications

### Processor
- **Model:** Intel Core i7-14700KF
- **Generation:** 14th Gen (Raptor Lake Refresh)
- **Cores:** 20 cores (8 P-cores + 12 E-cores)
- **Threads:** 28 logical processors
- **Base Clock:** ~3.4 GHz
- **Boost Clock:** Up to 5.6 GHz (P-cores)
- **TDP:** 125W base / 253W maximum turbo (PL2)
- **Socket:** LGA 1700
- **Notes:** "KF" = unlocked multiplier, no integrated graphics

**Performance Assessment:** ⭐⭐⭐⭐⭐
- Flagship-class CPU for 2024
- Excellent for gaming, streaming, content creation
- Handles heavy multitasking with ease

### CPU Cooling
- **Model:** Corsair H150i ELITE LCD XT
- **Type:** All-In-One (AIO) Liquid Cooler
- **Radiator Size:** 360mm (3x 120mm fans)
- **Features:**
  - LCD screen on pump head (customizable display)
  - RGB lighting
  - iCUE software control
  - High-performance ML120 fans
- **Performance Rating:** Premium tier AIO

**Cooling Assessment:** ⭐⭐⭐⭐⭐
- ✅ **EXCELLENT CHOICE** for i7-14700KF
- 360mm radiator easily handles 253W TDP
- One of Corsair's flagship AIO models
- LCD display allows real-time temp monitoring
- More than adequate cooling headroom

**Expected Thermal Performance:**
- Idle: 30-40°C
- Gaming: 55-70°C
- Full Load: 70-85°C
- **No thermal throttling expected** with this cooler

### Motherboard
- **Model:** ASRock Z790 Steel Legend WiFi
- **Chipset:** Intel Z790 (enthusiast tier)
- **Form Factor:** ATX
- **Serial:** M80-G500870030**
- **Features:**
  - Overclocking support (Z790 chipset)
  - WiFi 6E + Bluetooth
  - Multiple M.2 slots for NVMe SSDs
  - PCIe 5.0 support
  - Advanced power delivery for overclocking

**BIOS Information:**
- **Vendor:** American Megatrends International (AMI)
- **Version:** 21.02
- **Date:** 08.10.2025
- **Type:** UEFI
- **Status:** ✅ Latest BIOS (October 2025)

### Memory (RAM)
- **Capacity:** 64 GB (2x 32GB modules)
- **Manufacturer:** Corsair
- **Type:** DDR5
- **Speed:** 4800 MT/s (DDR5-4800)
- **Configuration:** Dual Channel
- **Slots Used:** 2 of 4 (DIMM1 on each channel)
- **Expansion:** Can upgrade to 128GB or 192GB

**Performance Assessment:** ⭐⭐⭐⭐⭐
- Excellent capacity for professional workloads
- DDR5 provides future-proofing
- Dual channel properly configured
- Room for upgrade if needed

**Recommendation:** DDR5-4800 is on the slower side for DDR5. Consider enabling XMP/EXPO profile in BIOS if not already enabled (can boost to 5200+ MT/s).

### Storage

#### Drive 1: Samsung SSD 990 EVO Plus 4TB
- **Type:** NVMe PCIe 4.0 SSD
- **Capacity:** 4 TB (4,000,787,030,016 bytes)
- **Health:** ✅ Healthy
- **Performance:** Sequential Read up to 7,250 MB/s
- **Use Case:** Primary storage, games library

#### Drive 2: Samsung SSD 980 PRO 2TB
- **Type:** NVMe PCIe 4.0 SSD
- **Capacity:** 2 TB (2,000,398,934,016 bytes)
- **Health:** ✅ Healthy
- **Performance:** Sequential Read up to 7,000 MB/s
- **Use Case:** OS boot drive / secondary storage

#### Drive 3: Samsung SSD 980 PRO 2TB
- **Type:** NVMe PCIe 4.0 SSD
- **Capacity:** 2 TB (2,000,398,934,016 bytes)
- **Health:** ✅ Healthy
- **Performance:** Sequential Read up to 7,000 MB/s
- **Use Case:** Professional work / media storage

**Total Storage:** 8 TB NVMe SSD (all high-performance)

**Storage Assessment:** ⭐⭐⭐⭐⭐
- Flagship-tier storage configuration
- All PCIe 4.0 NVMe drives (latest gen)
- 990 EVO Plus is newest Samsung consumer SSD (2024)
- 980 PRO is professional-grade
- Zero mechanical drives = silent, fast, reliable

### Graphics Card
- **Model:** NVIDIA GeForce RTX 4070 Ti SUPER
- **VRAM:** ~4GB (detected as 4,293,918,720 bytes)
- **Driver:** 32.0.15.8180
- **Refresh Rate:** 239 Hz (likely 240Hz gaming monitor)
- **Generation:** NVIDIA 40-series (Ada Lovelace architecture)

**Performance Assessment:** ⭐⭐⭐⭐⭐
- High-end gaming GPU (2024)
- Excellent for 1440p/4K gaming
- Ray tracing capable
- DLSS 3.0 support
- Professional workloads (video editing, 3D rendering)

**Note:** VRAM detection appears incorrect (should be 16GB). This is a Windows reporting quirk.

### Network Adapters

#### 1. Realtek Gaming 2.5GbE (Motherboard)
- **Status:** ❌ Disconnected
- **Speed:** 2.5 Gbps
- **Type:** Ethernet (wired)

#### 2. Killer Wi-Fi 6E AX1675x (Motherboard)
- **Status:** ❌ Disconnected
- **Speed:** Up to 2.4 Gbps
- **Frequency:** 2.4GHz / 5GHz / 6GHz
- **Standard:** Wi-Fi 6E (latest)

#### 3. Bluetooth (Motherboard)
- **Status:** ❌ Disconnected

#### 4. Realtek USB 2.5GbE Adapter
- **Status:** ✅ Connected and Active
- **IP Address:** 192.168.99.6
- **DHCP Server:** 192.168.99.1
- **Speed:** 2.5 Gbps
- **Type:** USB Ethernet adapter

**Network Assessment:**
- Currently using USB Ethernet adapter instead of motherboard NICs
- Built-in 2.5GbE and WiFi 6E are not in use
- **Recommendation:** Check why motherboard Ethernet is disconnected. Built-in NIC typically has better performance than USB adapters.

---

## Thermal Analysis & Cooling Recommendations

### CPU Thermal Considerations

**i7-14700KF Thermal Profile:**
- **Base TDP:** 125W
- **Max Turbo Power (PL2):** 253W
- **Tjunction Max:** 100°C
- **Recommended Max:** 85°C sustained

**✅ THERMAL ANALYSIS: EXCELLENT**

Your **Corsair H150i ELITE LCD XT (360mm AIO)** is a **premium cooling solution** that **exceeds the requirements** for the i7-14700KF (253W TDP).

**Cooling Capacity:**
- Corsair H150i ELITE LCD XT can handle **up to 300W+**
- i7-14700KF draws up to 253W under full load
- **Thermal headroom:** ~50W+ spare capacity
- **Expected Result:** No thermal throttling, even under heavy sustained workloads

**Expected Temperature Ranges (with H150i):**
- **Idle:** 30-40°C
- **Gaming:** 55-70°C
- **All-Core Workload (100%):** 70-85°C
- **Peak (short bursts):** 80-90°C (acceptable)

**AIO Configuration Tips:**
1. **Radiator Mounting:** Top or front of case (exhaust preferred for CPU temps)
2. **Fan Configuration:** Set to intake if front-mounted, exhaust if top-mounted
3. **iCUE Software:** Use Corsair iCUE to monitor pump speed and set fan curves
4. **Pump Speed:** Should run at 2000-3000 RPM (check in iCUE)

**Monitoring Recommendations:**

**ON WINDOWS DESKTOP:** Use Corsair iCUE + HWiNFO64 for comprehensive monitoring:

**Option 1: Corsair iCUE (Recommended)**
- Download: https://www.corsair.com/icue
- View real-time temps on LCD screen
- Monitor pump speed (should be 2000-3000 RPM)
- Set custom fan curves
- Configure LCD display (temps, GIF, system stats)

**Option 2: HWiNFO64 (Detailed Monitoring)**
- Download: https://www.hwinfo.com/download/
- Check "Sensors Only" mode
- Monitor:
  - CPU Package Temp (should be under 85°C under load)
  - CPU Core Max (individual core temps)
  - CPU Power Draw (up to 253W is normal)
  - Coolant Temp (if available via iCUE Link)

**✅ Your cooling is excellent - no thermal concerns expected.**

### GPU Thermal Profile

**RTX 4070 Ti SUPER:**
- **TDP:** 285W
- **Max Temp:** 83-85°C (NVIDIA target)
- **Cooling:** Factory cooler (2-3 fan design)

**Monitoring:**
- Use HWiNFO64 or MSI Afterburner
- GPU temps should stay under 80°C while gaming
- If over 83°C → check case airflow, clean dust filters

### System Airflow Recommendations

**Current Setup (with H150i ELITE LCD XT):**
- **AIO Radiator:** 360mm (3x 120mm fans) - top or front mounted
- **Additional Fans:** Front intake (if AIO is top-mounted) or top exhaust (if AIO is front-mounted)
- **Rear Exhaust:** 1x 120/140mm fan (standard)

**Optimal Configuration:**
1. **Option A: AIO Top-Mounted (Best for CPU)**
   - Top: 3x 120mm (H150i) as exhaust
   - Front: 3x 120/140mm intake fans
   - Rear: 1x 120/140mm exhaust
   - **Result:** Best CPU temps, slightly warmer GPU

2. **Option B: AIO Front-Mounted (Balanced)**
   - Front: 3x 120mm (H150i) as intake
   - Top: 2x 120/140mm exhaust
   - Rear: 1x 120/140mm exhaust
   - **Result:** Balanced temps, cooler GPU

**Airflow Tips:**
- **Positive pressure:** Slightly more intake than exhaust (reduces dust)
- Clean dust filters monthly (especially important with AIO radiator)
- Ensure radiator fins are clean (compressed air every 6 months)

**Cable Management:**
- Route AIO tubes to avoid kinks
- Route cables behind motherboard tray
- Keep airflow path clear from front to back
- Zip-tie loose cables

---

## BIOS Optimization Recommendations

**⚠️ Access BIOS:** Restart PC → Press **F2** or **DEL** during boot (ASRock boards)

### Priority #1: Enable XMP/EXPO for RAM
- Navigate to: **OC Tweaker** → **DRAM Configuration**
- Enable: **XMP Profile 1** or **EXPO Profile**
- This will boost RAM from 4800 MT/s to its rated speed (likely 5200-6000 MT/s)
- **Expected Result:** 10-15% better performance in some workloads

### Priority #2: CPU Power Limits (Optional with H150i)
✅ **With your Corsair H150i, you can safely run at default power limits.**

If you want even cooler/quieter operation (optional):
- Navigate to: **OC Tweaker** → **CPU Configuration**
- **PL1 (Long Duration Power):** 125W (Intel spec)
- **PL2 (Short Duration Power):** 253W (default) or 200W for cooler operation
- **Tau (Turbo Duration):** 28 seconds (default)
- **Impact:** Minimal performance difference, slightly better thermals

### Priority #3: AIO Pump & Fan Curves
- Navigate to: **H/W Monitor** → **Fan Control**
- **AIO Pump (CPU_PUMP header):**
  - Set to **100% (Full Speed)** or **PWM Mode** if available
  - Pump should always run at maximum for best performance
  - ⚠️ Never set pump below 50%

- **AIO Fans (CPU_FAN or AIO_PUMP header):**
  - **Option 1:** Use iCUE software for fan control (recommended)
  - **Option 2:** BIOS fan curve:
    - 40% @ 40°C
    - 60% @ 60°C
    - 80% @ 75°C
    - 100% @ 85°C

- **Case Fans (SYS_FAN headers):**
  - Similar curve but less aggressive
  - 30% @ 40°C → 100% @ 80°C

### Priority #4: Security Features
- Enable: **Secure Boot** (Windows 11 requirement)
- Enable: **TPM 2.0** (should be enabled, required for Win11)
- Enable: **Virtualization (Intel VT-x)** (useful for VMs, WSL2)

---

## Performance Benchmarks (Expected)

### Gaming Performance
- **1080p Ultra:** 200+ FPS (esports titles), 100-144 FPS (AAA)
- **1440p Ultra:** 120-165 FPS (most games)
- **4K High:** 60-100 FPS (AAA titles)

### Professional Workloads
- **Video Editing (4K):** Real-time playback, fast rendering
- **3D Rendering:** Excellent (CPU has 20 cores, GPU supports CUDA)
- **Compiling Code:** Very fast (28 threads)
- **Virtual Machines:** Can run 4-6 VMs comfortably with 64GB RAM

---

## Upgrade Path & Future-Proofing

### Current Lifespan: 4-6 years (2025-2029/2031)

**No Upgrades Needed Currently:**
- This is a flagship-tier system
- All components are current generation (2024)
- 64GB RAM is plenty for 99% of use cases
- Storage is excellent

### Potential Future Upgrades (2027+):

**1. RAM Expansion (If Needed)**
- Current: 64GB (2x 32GB)
- Max Supported: 192GB (4x 48GB) or 128GB (4x 32GB)
- Use Case: Heavy video editing, VMs, scientific computing
- Cost: ~€200-400 for 2x 32GB DDR5

**2. Storage Expansion**
- Z790 Steel Legend has multiple M.2 slots
- Can add another 2-4TB NVMe SSD
- Cost: €150-300 per 2TB

**3. CPU Upgrade (Not Recommended)**
- LGA 1700 socket is end-of-life (14th gen is last)
- i9-14900K/KS are only marginal upgrades (~15-20% more)
- **Better:** Wait for platform upgrade (LGA 1851, DDR5-6400+) in 2027+

**4. GPU Upgrade (2027+)**
- RTX 4070 Ti SUPER will be strong for 3-4 years
- Next upgrade: RTX 60-series or AMD RDNA 5 (2027)
- Estimated upgrade cycle: Every 3-4 generations

---

## Known Issues & Troubleshooting

### Issue: Motherboard Ethernet Not Working
**Symptoms:** Realtek 2.5GbE shows "Media disconnected"

**Possible Causes:**
1. Cable not plugged in
2. Driver issue
3. Disabled in BIOS
4. Windows disabled the adapter

**Fix Steps (ON WINDOWS DESKTOP):**
1. Check physical cable connection
2. Update Realtek drivers from ASRock website
3. Check Device Manager → Network Adapters → Enable if disabled
4. Check BIOS → Advanced → Onboard Devices → Enable LAN

### Issue: WiFi 6E Not Working
**Symptoms:** Killer WiFi shows "Media disconnected"

**Possible Causes:**
1. WiFi disabled in Windows
2. Driver issue
3. Airplane mode enabled

**Fix Steps (ON WINDOWS DESKTOP):**
1. Check WiFi toggle in Windows taskbar
2. Update Killer WiFi drivers
3. Disable Airplane mode (Windows Settings)

---

## Maintenance Schedule

### Monthly
- ✅ Check temperatures with HWiNFO64
- ✅ Clean dust filters on case
- ✅ Check for Windows updates
- ✅ Check for GPU driver updates (GeForce Experience)

### Every 6 Months
- ✅ Clean inside of case with compressed air
- ✅ Check fan operation (all spinning freely)
- ✅ Update motherboard BIOS (if new version available)
- ✅ Run SMART checks on SSDs (CrystalDiskInfo)

### Every 2-3 Years
- ✅ Replace thermal paste on CPU (if temps increasing)
- ✅ Replace case fans if noisy/failing
- ✅ Deep clean entire system

---

## Warranty Information

### Typical Warranty Periods
- **CPU:** 3 years (Intel retail box)
- **Motherboard:** 3 years (ASRock)
- **RAM:** Lifetime (Corsair)
- **SSD:** 5 years (Samsung)
- **GPU:** 3 years (NVIDIA/Partner brand)

**Installation Date:** 29.01.2025
**Warranty Expires (CPU/Mobo/GPU):** ~29.01.2028

**⚠️ Keep your purchase receipts!**

---

## Component Value Assessment

**Total System Value (New):** €2,800-3,800

| Component | Estimated Value (New) |
|-----------|----------------------|
| i7-14700KF | €400-450 |
| Z790 Steel Legend WiFi | €250-300 |
| 64GB DDR5-4800 Corsair | €200-250 |
| Corsair H150i ELITE LCD XT | €230-270 |
| RTX 4070 Ti SUPER | €900-1,000 |
| Samsung 990 EVO Plus 4TB | €300-350 |
| 2x Samsung 980 PRO 2TB | €300-350 (total) |
| Case + PSU + Accessories | €200-300 |

---

## Expert Assessment Summary

### Strengths ✅
- Flagship-tier CPU (i7-14700KF) - excellent for all workloads
- **Premium cooling (Corsair H150i ELITE LCD XT 360mm AIO)** - exceeds requirements
- High-end GPU (RTX 4070 Ti SUPER) - great for gaming/creation
- Excellent storage (8TB total, all NVMe SSDs)
- Premium motherboard (Z790 chipset, overclocking capable)
- Generous RAM (64GB DDR5)
- Latest BIOS (October 2025)
- Modern connectivity (WiFi 6E, 2.5GbE, USB 3.2)
- LCD display on AIO for real-time monitoring

### Areas for Optimization ⚠️
1. **RAM Speed:** DDR5-4800 is base speed, likely has XMP for 5200+
   - **Action Required:** Enable XMP in BIOS for 10-15% boost
   - **Impact:** Noticeable performance improvement in memory-intensive tasks

2. **Network Configuration:** Using USB Ethernet instead of motherboard NIC
   - **Action Required:** Troubleshoot why motherboard Ethernet is disconnected
   - **Impact:** Minor performance difference, but built-in is preferred

### Bottleneck Analysis
- **CPU to GPU Ratio:** ✅ Well balanced (i7-14700KF won't bottleneck RTX 4070 Ti SUPER)
- **RAM to CPU:** ✅ 64GB is more than adequate
- **Storage Speed:** ✅ All PCIe 4.0 NVMe (no bottlenecks)
- **Cooling:** ✅ **EXCELLENT** - Corsair H150i ELITE LCD XT exceeds requirements

### System Rating

**Overall Build Quality:** ⭐⭐⭐⭐⭐ (5/5)
**Performance Tier:** Flagship / Enthusiast
**Value for Money:** ⭐⭐⭐⭐⭐ (5/5) - Premium components with excellent balance
**Future-Proofing:** ⭐⭐⭐⭐⭐ (5/5) - Will last 4-6 years easily
**Thermal Performance:** ✅ **EXCELLENT** - Premium 360mm AIO

---

## Next Steps & Action Items

### Immediate (This Week)

1. **Install HWiNFO64 (ON WINDOWS DESKTOP)**
   - Download: https://www.hwinfo.com/download/
   - Monitor CPU/GPU temperatures
   - Report back if temps exceed 85°C under load

2. **Enable XMP in BIOS**
   - Restart → Press F2/DEL
   - OC Tweaker → Enable XMP Profile 1
   - Save & Exit
   - Boot Windows and verify RAM speed increased (use CPU-Z)

3. **Fix Motherboard Ethernet**
   - Check cable connection
   - Update Realtek drivers from ASRock support page
   - Test connectivity on motherboard NIC instead of USB

### Short Term (This Month)

4. **Run Storage Health Check (ON WINDOWS DESKTOP)**
   - Download CrystalDiskInfo: https://crystalmark.info/
   - Check SMART status of all 3 SSDs
   - Verify "Good" health status

5. **Update GPU Drivers**
   - Use NVIDIA GeForce Experience
   - Install latest Game Ready Driver

6. **Benchmark System (Optional)**
   - Run 3DMark or Cinebench R23
   - Compare scores to expected results
   - Verify system performing as expected

### Long Term (Ongoing)

7. **Monthly Temp Monitoring**
   - Check HWiNFO64 temps monthly
   - Watch for thermal degradation (thermal paste drying)

8. **BIOS Updates**
   - Check ASRock website quarterly for new BIOS
   - Update if significant improvements listed

---

## Additional Resources

### Monitoring Software (All Free)
- **HWiNFO64:** CPU/GPU temps, voltages, clocks - https://www.hwinfo.com/
- **CrystalDiskInfo:** SSD health monitoring - https://crystalmark.info/
- **MSI Afterburner:** GPU monitoring and overclocking - https://www.msi.com/Landing/afterburner
- **CPU-Z:** CPU/RAM identification - https://www.cpuid.com/softwares/cpu-z.html

### Driver Sources
- **Motherboard (ASRock):** https://www.asrock.com/mb/Intel/Z790%20Steel%20Legend%20WiFi/
- **GPU (NVIDIA):** https://www.nvidia.com/drivers or GeForce Experience
- **Chipset (Intel):** Windows Update or Intel Download Center

### Community Support
- r/buildapc (Reddit)
- r/pcmasterrace (Reddit)
- ASRock Forums
- Linus Tech Tips Forums

---

**Report Generated:** 12.12.2025
**System Status:** ✅ Excellent - No Critical Issues
**Thermal Status:** ⚠️ Requires Monitoring
**Next Review:** After thermal testing completion

---

**Need Help?**
If you have questions about this report or need assistance with any of the action items, just ask! I can guide you through BIOS settings, driver updates, or troubleshooting.
