# RPi WiFi Sentinel Setup

Reusable setup for Raspberry Pi with USB WiFi adapter (RTL8812AU) for monitoring while keeping built-in wlan0 for stable management.

## Features
- max_usb_current=1 in /boot/firmware/config.txt for USB power.
- 25s power delay only on USB path.
- Safe monitor mode on wlan1mon (no airmon-ng check kill that breaks management).
- Management-only fallback on wlan0 with recon disabled.
- bettercap caplet with early api.rest on.
- Systemd unit with sufficient TimeoutStartSec.
- Watchers for boot-race recovery.

## Setup
1. Copy files to ~/wifi-sentinel on target Pi.
2. Edit PI_IP and other variables in scripts.
3. sudo cp bettercap.service /etc/systemd/system/
4. sudo systemctl daemon-reload && sudo systemctl enable --now bettercap.service
5. For driver: sudo apt install realtek-rtl88xxau-dkms (or build 8812au driver).

See fix-pi-bettercap.sh for the main logic.

**Do not commit real IPs, passwords, or host-specific paths.** Use placeholders.


