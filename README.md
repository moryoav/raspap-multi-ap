# RaspAP Multi-AP and Auto-Connect Scripts

This repository provides a turnkey solution for managing multiple WiFi access points (APs) and dynamic internet connectivity on a Raspberry Pi running RaspAP. It bundles two shell scripts and a sample crontab configuration to automate setup at boot.

---

## 📂 Repository Structure

```
raspap-multi-ap/
├── raspap-post-boot.sh       # Configures IP forwarding, NAT, and dual AP on boot
├── wifi-autoconnect.sh       # Auto-connects a client interface to an external network
└── README.md                 # Project overview and installation guide
```

---

## ⚙️ Requirements

- **Hardware:**
  - Raspberry Pi 4B (8 GB)
  - Argon One SSD Case (boot from SSD) — [Argon One SSD Case on AliExpress](https://s.click.aliexpress.com/e/_ok2dH6D)
  - Two USB WiFi dongles (`wlan1`, `wlan2`) — [USB WiFi Dongle on AliExpress](https://s.click.aliexpress.com/e/_opmgjI1)
- **Software:**
  - [RaspAP Installed](https://docs.raspap.com/) (for hostapd, DNS, DHCP)
  - [Follow the semi-official guide to set up two APs](https://github.com/RaspAP/raspap-docs/blob/310aa02fc135ed471d1901ad0d057672a2af9cea/docs/multiple.md). This is not enough to get it to work, but something you need to do first to start.

> I can’t recommend the Argon One SSD Case enough — booting from an SSD is significantly faster and more reliable than using an SD card. Likewise, these USB WiFi dongles just work out of the box (no driver tweaks) and deliver blazing‑fast WiFi 6E performance.



## 🔌 USB Power Considerations

On the Raspberry Pi 4 Model B, all four USB ports (two USB 3.0 and two USB 2.0) share a downstream current limit of approximately **1.1 A total**, as specified in the official datasheet ([DATASHEET Raspberry Pi 4 Model B](https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-datasheet.pdf)). The Raspberry Pi 5 initially limits downstream USB current to **0.6 A shared across all ports**, but when paired with a USB-PD 5 V 5 A power supply that negotiates correctly, it raises the limit to **1.6 A total** ([How does Pi5 determine Power Supply capacity](https://forums.raspberrypi.com/viewtopic.php?t=358576), [USB-PD - Explaining the Power Standard in the Raspberry Pi 5](https://community.element14.com/technologies/power-management/b/blog/posts/usb-power-delivery-explained---is-usb-pd-the-future-of-charging)). Additionally, the Pi 5’s exposed PCIe Gen2 x1 connector lets you attach an NVMe SSD directly—freeing all USB ports and often obviating the need for a powered hub altogether ([NVMe SSD boot with the Raspberry Pi 5 - Jeff Geerling](https://www.jeffgeerling.com/blog/2023/nvme-ssd-boot-raspberry-pi-5)).


On a Pi 4, adding an unpowered USB hub does **not** increase available current, and so you will not be able to run both the SSD *and* the two WiFi dongles. To reliably run two high-speed WiFi adapters, you **must** use a powered USB hub. Here are three proven options:

- [Powered USB Hub Option 1](https://s.click.aliexpress.com/e/_oo2iZ6h)  
- [Powered USB Hub Option 2](https://s.click.aliexpress.com/e/_oD9R1Qh)  
- [Powered USB Hub Option 3](https://s.click.aliexpress.com/e/_oDR2fk9)

---

## 🚀 Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/moryoav/raspap-multi-ap.git
   cd raspap-multi-ap
   ```

2. **Install scripts**

   ```bash
   sudo cp raspap-post-boot.sh wifi-autoconnect.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/raspap-post-boot.sh \
                 /usr/local/bin/wifi-autoconnect.sh
   ```

3. **Configure cron**

   Open root crontab:
   ```bash
   sudo crontab -e
   ```
   Add the following two lines to run scripts on reboot:
   ```cron
   @reboot /usr/local/bin/raspap-post-boot.sh &
   @reboot /usr/local/bin/wifi-autoconnect.sh
   ```

4. **Reboot device**

   ```bash
   sudo reboot
   ```

---

## ⚙️ Script Configuration

### 1. `raspap-post-boot.sh`
- **Location:** `/usr/local/bin/raspap-post-boot.sh`
- **Purpose:**
  1. Waits for RaspAP to initialize (~30s).
  2. Enables IP forwarding.
  3. Clears old NAT on `wlan1` and adds NAT on `wlan2`.
  4. Restarts `hostapd` with both AP configurations (`wlan0`, `wlan1`).
- **Customizable variables:**
  - Hostapd config paths (default `/etc/hostapd/wlan0.conf`, `/etc/hostapd/wlan1.conf`).
  - Sleep durations for hardware initialization.

### 2. `wifi-autoconnect.sh`
- **Location:** `/usr/local/bin/wifi-autoconnect.sh`
- **Purpose:**
  1. Rotates `/var/log/wpa_autoconnect.log` to keep last 100 lines.
  2. Waits for the boot script to finish (~30s).
  3. Cleans up stale `wpa_supplicant` sockets/processes on specified interface.
  4. Launches `wpa_supplicant` to connect `IFACE` to the network defined in `/etc/wpa_supplicant/wpa_supplicant.conf`.
- **Customizable variables:**
  - `IFACE`: name of the client interface (default `wlan2`).
  - `CFG`: path to the wpa_supplicant configuration file.
  - Log file location (default `/var/log/wpa_autoconnect.log`).

---

## 📋 How It Works

1. **On Boot:** Cron triggers `raspap-post-boot.sh` and `wifi-autoconnect.sh`.
2. **Dual AP Setup:**
   - `raspap-post-boot.sh` waits for RaspAP, then:
     - Enables kernel IP forwarding.
     - Configures NAT so that client traffic on `wlan2` is masqueraded.
     - Restarts `hostapd` with separate SSIDs on `wlan0` (2.4 GHz) and `wlan1` (5 GHz).
3. **Internet Client:**
   - `wifi-autoconnect.sh` brings up `wlan2` as a station using `wpa_supplicant`, so that RaspAP can bridge client traffic through `wlan2` to the upstream network.

---

## 📝 Logging

- **RaspAP Post-Boot Log:** `/var/log/raspap-post-boot.log`
- **Auto-Connect Log:** `/var/log/wpa_autoconnect.log`

Check these logs to verify successful execution or diagnose errors.

---

## 🛠 Troubleshooting

- Ensure both scripts are executable (`chmod +x`).
- Confirm interface names match (`ip a`).
- Adjust `sleep` durations if hardware initialization is slower.
- Check `/var/log/raspap-post-boot.log` and `/var/log/wpa_autoconnect.log` for errors.
- Manually run the scripts to isolate issues:
  ```bash
  sudo /usr/local/bin/raspap-post-boot.sh
  sudo /usr/local/bin/wifi-autoconnect.sh
  ```

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests with enhancements.


