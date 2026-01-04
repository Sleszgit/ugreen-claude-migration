## Network Configuration Requirements (CRITICAL UGREEN FIXES)

The automation script must implement the following specific network configurations to support VLANs on Ugreen hardware.

### 1. Interface Configuration (`nic1`)
**Constraint:** You must disable hardware VLAN offloading. The Ugreen network drivers (Intel/Aquantia) have a bug where they strip VLAN tags before the bridge sees them unless this is disabled.
* **Action:** In `/etc/network/interfaces`, the `nic1` block must include the `post-up` command below.
* **Required Configuration:**
    ```bash
    auto nic1
    iface nic1 inet manual
        # CRITICAL FIX: Disable hardware VLAN offloading for UGREEN
        post-up /sbin/ethtool -K nic1 rx-vlan-filter off tx-vlan-offload off
    ```

### 2. Bridge Configuration (`vmbr0`)
**Constraint:** The bridge must be VLAN-aware and configured with specific PVIDs.
* **IP Address:** 192.168.40.60/24
* **Gateway:** 192.168.40.1
* **Required Configuration:**
    ```bash
    auto vmbr0
    iface vmbr0 inet static
        address 192.168.40.60/24
        gateway 192.168.40.1
        bridge-ports nic1
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-pvid 40
        bridge-vids 10 40
    ```

### 3. Verification Steps (Post-Script Execution)
After applying the configuration, the script (or you) must verify success using these commands:

1.  **Check Offloading Status:**
    `ethtool -k nic1 | grep vlan`
    * *Success Criteria:* `rx-vlan-filter` and `tx-vlan-offload` must be **off**.

2.  **Check Bridge Registration:**
    `bridge vlan show`
    * *Success Criteria:* `nic1` and `vmbr0` must show VLAN 10 and VLAN 40 (PVID Egress Untagged).