# Physical Hardware Inventory

**Last Updated:** 2025-12-18

This file contains all **physical hardware** in the homelab. These are actual machines and components that rarely change.

---

## Primary Proxmox Server (Custom Build)

**Hostname:** pve
**Purpose:** Main virtualization host running Proxmox VE
**Network:** 192.168.40.x network
**Status:** Active
**Admin User:** sshadmin (requires sudo for pct/qm commands)

### Components

1. **CPU:** Intel Core i5-13500 (14 cores: 6P+8E cores) - 874.58 PLN
2. **Motherboard:** MSI MPG B760I EDGE WIFI (Mini-ITX) - 946.90 PLN
3. **RAM:** Corsair Vengeance 96 GB DDR5 - 1,053.48 PLN
4. **Storage:** Crucial P3 1TB NVMe SSD - 249.00 PLN
5. **Storage Expansion:** M.2 to 5x SATA Adapter - 141.00 PLN
6. **CPU Cooler:** Noctua NH-L9i-KPC - 169.00 PLN
7. **Case:** Jonsbo N3 (after discount) - 683.88 PLN
8. **Power Supply:** Corsair SF850 (850W SFX) - 781.03 PLN

**Total Build Cost:** 4,898.87 PLN

### Capabilities
- **CPU Performance:** 14 cores (6 P-cores @ 5.1 GHz boost, 8 E-cores @ 3.5 GHz boost)
- **RAM:** 96 GB DDR5 - excellent for running 20+ VMs/LXCs
- **Storage:** 1TB NVMe boot drive
- **Storage Expansion:** Up to 6 drives total (1x NVMe + 5x SATA via adapter)
- **Network:** Built-in WiFi + Gigabit Ethernet
- **Form Factor:** Compact Mini-ITX build
- **Power Efficiency:** 850W PSU provides plenty of headroom

---

## NAS Devices

### Synology DS918+

**Type:** 4-bay NAS
**Network:** 192.168.40.x network
**Status:** Active
**Year:** 2018 model

**Specifications:**
- **CPU:** Intel Celeron J3455 (quad-core 1.5-2.3 GHz)
- **RAM:** Expandable up to 8GB (stock: 4GB)
- **Drive Bays:** 4x 3.5"/2.5" SATA
- **Expansion:** 2x M.2 NVMe SSD slots for cache (2280 form factor)
- **Network:** 2x Gigabit Ethernet (link aggregation capable)
- **Max Single Volume:** 108 TB
- **Max Capacity:** ~64TB (4x 16TB drives)
- **Btrfs Support:** Yes
- **Hardware Encryption:** Yes (AES-NI)

**Primary Use Cases:**
- File storage and sharing (SMB/NFS/AFP)
- Docker container host (Docker support via DSM)
- Backup target
- Media server (Plex, Jellyfin capable with hardware transcoding)
- Surveillance Station (4 camera licenses included)
- Snapshot replication

---

### Synology DS920+

**Type:** 4-bay NAS
**Network:** 192.168.40.x or 10.10.10.x network
**Status:** Active
**Year:** 2020 model

**Specifications:**
- **CPU:** Intel Celeron J4125 (quad-core 2.0-2.7 GHz)
- **RAM:** Expandable up to 8GB (stock: 4GB)
- **Drive Bays:** 4x 3.5"/2.5" SATA
- **Expansion:** 2x M.2 NVMe SSD slots for cache (2280 form factor)
- **Network:** 2x Gigabit Ethernet (link aggregation capable)
- **Max Single Volume:** 108 TB
- **Max Capacity:** ~72TB (4x 18TB drives)
- **Hardware Transcoding:** Yes (Intel Quick Sync Video)
- **Btrfs Support:** Yes
- **Hardware Encryption:** Yes (AES-NI)

**Primary Use Cases:**
- File storage and sharing (SMB/NFS/AFP)
- Docker container host
- Backup automation host (GitHub backup scripts)
- Media transcoding (Plex, Jellyfin with hardware acceleration)
- Virtualization (Virtual Machine Manager - up to 2 VMs)
- Snapshot replication

**Improvements over DS918+:**
- Faster CPU (J4125 vs J3455)
- Better hardware transcoding
- More RAM slots

---

### UGREEN DXP4800 Plus

**Type:** 4-bay NAS
**Network IP:** 192.168.40.60
**Status:** Active - Primary Portainer Host
**Year:** 2024 model
**Serial Number:** EC752JJ372539F78

**Specifications:**
- **CPU:** Intel N100 (quad-core Alder Lake-N, up to 3.4 GHz)
- **RAM:** 8GB DDR5 (expandable to 16GB)
- **Drive Bays:** 4x 3.5" SATA (hot-swappable)
- **NVMe Storage:** 2TB WD_BLACK SN7100 (PCIe 4.0 x4, dedicated Proxmox storage)
  - ZFS pool: nvme2tb
  - Compression: LZ4 (~50% space savings)
  - Auto-TRIM enabled
  - Used for VM/LXC storage
- **System Storage:** 119GB NVMe (Proxmox boot drive)
- **Network:** 2x 2.5 Gigabit Ethernet (Intel i226-V)
- **OS:** Proxmox VE (bare metal hypervisor)
- **Max Capacity:** ~80TB (4x 20TB drives in SATA bays)
- **USB Ports:** 2x USB 3.2 Gen2 (10 Gbps)
- **Video Output:** HDMI 2.0
- **Power:** ~15W idle, ~65W max

**Primary Use Cases:**
- Docker container orchestration
- **Portainer Server:** Centralized management for all Docker environments
- File storage (SMB/NFS)
- Network services
- Media streaming

**Advantages:**
- 2.5 GbE networking (faster than 1 GbE on Synology)
- Proxmox VE hypervisor - full virtualization platform
- 2TB NVMe with ZFS - fast storage for VMs/LXCs
- LZ4 compression - ~50% space savings with minimal CPU overhead
- Intel N100 - modern, efficient CPU with hardware virtualization
- DDR5 RAM
- Lower power consumption than traditional servers

---

## Network Equipment (UniFi/Ubiquiti)

**Network:** 192.168.99.x management network
**Controller:** UDM Pro (built-in)
**Status:** Active - all devices up to date
**Software Versions:**
- UniFi OS: 4.4.6
- Network Application: 10.0.160

### UDM Pro (UniFi Dream Machine Pro)

**Type:** All-in-one router, controller, and security gateway
**IP Address:** 192.168.99.1
**MAC Address:** 24:5a:4c:53:36:f5
**Status:** Online

**Specifications:**
- **Processor:** Quad-core ARM Cortex-A57 @ 1.7 GHz
- **RAM:** 4GB DDR4
- **Storage:** 128GB eMMC + 1x 3.5" HDD bay for UniFi Protect
- **WAN Ports:** 1x RJ45 Gigabit, 1x SFP+ (10 Gbps)
- **LAN Ports:** 8x RJ45 Gigabit
- **SFP+ Ports:** 1x 10 Gbps
- **Screen:** 1.3" touchscreen display
- **Rack Mount:** 1U rack-mountable

**Features:**
- Built-in UniFi Network Controller
- Deep Packet Inspection (DPI)
- Advanced firewall and routing
- VPN server (site-to-site and remote access)
- UniFi Protect ready (NVR functionality)
- IDS/IPS (Intrusion Detection/Prevention)
- Traffic analytics and insights

**Primary Use Cases:**
- Central network controller
- Router and gateway
- VLAN management
- Network security (firewall, IDS/IPS)
- VPN gateway
- Traffic monitoring and analytics

---

### USW Lite 8 PoE

**Type:** Compact 8-port managed PoE switch
**IP Address:** 192.168.99.4
**MAC Address:** 6c:63:f8:7f:04:27
**Status:** Up to date

**Specifications:**
- **Ports:** 8x Gigabit RJ45 (4x PoE+, 4x non-PoE)
- **PoE Budget:** 52W total
- **PoE Standard:** 802.3af/at (PoE+)
- **Switching Capacity:** 16 Gbps
- **Forwarding Rate:** 11.9 Mpps
- **Power:** 60W max (passive PoE input or AC adapter)
- **Form Factor:** Compact fanless design
- **Management:** UniFi Controller

**Features:**
- Managed Layer 2 switching
- VLAN support
- Port isolation
- Storm control
- PoE+ on 4 ports (max 30W per port)
- Fanless, silent operation
- Wall or desk mountable

**Primary Use Cases:**
- Powering PoE devices (access points, cameras, VoIP phones)
- Desktop or small area switching
- VLAN segmentation
- Quiet environments (fanless)

---

### USW Pro Max 16 PoE

**Type:** 16-port enterprise managed PoE switch
**IP Address:** 192.168.99.2
**MAC Address:** 1c:6a:1b:45:e9:74
**Status:** Up to date

**Specifications:**
- **Ports:** 16x 2.5 GbE RJ45 (all PoE++)
- **SFP+ Ports:** 2x 10 Gbps uplink
- **PoE Budget:** 400W total
- **PoE Standard:** 802.3bt (PoE++) - up to 60W per port
- **Switching Capacity:** 120 Gbps
- **Forwarding Rate:** 89.28 Mpps
- **Power:** 450W AC input
- **Form Factor:** 1U rack-mountable
- **Management:** UniFi Controller
- **Display:** 1.3" touchscreen

**Features:**
- Managed Layer 2/3 switching
- 2.5 Gbé on all ports (faster than standard Gigabit)
- High-power PoE++ (60W per port for WiFi 6/6E APs, PTZ cameras)
- 10 Gbps SFP+ uplinks
- Advanced VLAN configuration
- Link aggregation (LAG)
- Jumbo frames (9KB)
- Touchscreen for quick stats

**Primary Use Cases:**
- Core switch for high-performance network
- Powering WiFi 6/6E access points
- Powering PTZ cameras and high-power devices
- 2.5 GbE connectivity for NAS and servers
- 10 Gbps uplinks to storage or backbone

---

### AC Pro (UAP-AC-Pro)

**Type:** Dual-band WiFi 5 (802.11ac Wave 2) access point
**IP Address:** 192.168.99.3
**MAC Address:** 78:8a:20:4b:b4:e1
**Status:** Up to date

**Specifications:**
- **WiFi Standard:** 802.11ac Wave 2 (WiFi 5)
- **Bands:** Dual-band simultaneous (2.4 GHz + 5 GHz)
- **Max Speed:** 1300 Mbps (5 GHz) + 450 Mbps (2.4 GHz) = 1750 Mbps total
- **Antennas:** 3x3 MIMO
- **Range:** Up to 122m (400 ft)
- **Concurrent Users:** 250+ clients
- **Ethernet:** 1x Gigabit RJ45
- **PoE:** 802.3af (PoE) or 802.3at (PoE+) - passive 24V also supported
- **Power Consumption:** 9W max
- **Mounting:** Ceiling or wall mount included

**Features:**
- Managed via UniFi Controller
- Fast roaming (seamless handoff)
- Band steering (push clients to 5 GHz)
- Airtime fairness
- Guest portal and hotspot management
- VLAN tagging
- DPI (Deep Packet Inspection)
- Scheduled on/off
- Captive portal support

**Primary Use Cases:**
- Whole-home or office WiFi coverage
- Guest network isolation (VLAN)
- IoT device connectivity (2.4 GHz)
- High-density client environments
- Seamless roaming between APs

---

## Single Board Computers

### Raspberry Pi 400

**Type:** Keyboard-integrated Raspberry Pi 4
**Network:** 192.168.40.x network
**Status:** Active
**Year:** 2020

**Specifications:**
- **CPU:** Broadcom BCM2711 (quad-core Cortex-A72, 1.8 GHz)
- **RAM:** 4GB LPDDR4-3200
- **Storage:** microSD card slot (boot) + USB 3.0 for external drives
- **Network:** Gigabit Ethernet (via USB 3.0) + WiFi 5 (802.11ac) + Bluetooth 5.0
- **GPIO:** 40-pin header accessible via rear
- **USB Ports:** 3x USB 3.0, 1x USB 2.0
- **Video:** 2x micro HDMI (4K60 support)
- **Power:** USB-C 5V/3A

**Primary Use Cases:**
- Lightweight Docker host
- Network services
- Development/testing environment
- Always-on tasks (monitoring, automation)

---

### Raspberry Pi 3B

**Type:** Single board computer
**Network:** 192.168.40.x network
**Status:** Active
**Year:** 2016

**Specifications:**
- **CPU:** Broadcom BCM2837 (quad-core Cortex-A53, 1.2 GHz)
- **RAM:** 1GB LPDDR2
- **Storage:** microSD card slot
- **Network:** 100 Mbps Ethernet (via USB 2.0) + WiFi 4 (802.11n) + Bluetooth 4.1
- **GPIO:** 40-pin header
- **USB Ports:** 4x USB 2.0
- **Video:** HDMI (1080p60)
- **Power:** micro USB 5V/2.5A

**Primary Use Cases:**
- Lightweight services (DNS, monitoring agents)
- IoT gateway
- Testing environment

**Limitations:**
- Only 1GB RAM - suitable for lightweight tasks only
- 100 Mbps Ethernet - slower than Pi 400

---

## Physical Infrastructure Summary

| Category | Count | Details |
|----------|-------|---------|
| Proxmox Servers | 1 | Custom i5-13500 build, 96GB DDR5, 1TB NVMe |
| NAS Devices | 3 | DS918+, DS920+, UGREEN DXP4800+ |
| Single Board Computers | 2 | Raspberry Pi 400 (4GB), Pi 3B (1GB) |
| Total Physical RAM | 109+ GB | 96GB (Proxmox) + 8GB (UGREEN) + 4GB (Pi400) + 1GB (Pi3B) + NAS RAM |
| Total Drive Bays | 12 | 4x DS918+ + 4x DS920+ + 4x UGREEN |
| Total Storage Capacity | ~216+ TB | Max capacity across all NAS devices |
| Network Ports | 8x 1GbE, 2x 2.5GbE | Link aggregation capable on NAS devices |

---

## Power Consumption Estimates

| Device | Idle | Load | Annual Cost (€0.20/kWh) |
|--------|------|------|-------------------------|
| Proxmox Server | ~30W | ~100W | €52 - €175 |
| UGREEN DXP4800+ | ~15W | ~65W | €26 - €114 |
| Synology DS918+ | ~20W | ~40W | €35 - €70 |
| Synology DS920+ | ~20W | ~40W | €35 - €70 |
| Raspberry Pi 400 | ~3W | ~7W | €5 - €12 |
| Raspberry Pi 3B | ~2W | ~5W | €3 - €9 |
| **Total (24/7)** | **~90W** | **~257W** | **€158 - €450** |

*Based on typical usage patterns and European electricity rates*

---

## Notes for LLMs

**About Physical Hardware:**
- This file contains only physical, rarely-changing components
- For VMs, LXCs, services, and network topology → see `virtual-infrastructure.md`
- User has **full admin/root access** to all physical machines
- User prefers **web UI management** over CLI when available
- **Always use `sudo`** for Proxmox commands when logged in as sshadmin
