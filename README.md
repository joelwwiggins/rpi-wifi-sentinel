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
1. Clone `https://github.com/joelwwiggins/rpi-wifi-sentinel` and set `PI_IP` (default `192.168.10.117`).
2. From the repo on the Orin (or jump host): `./production-deploy.sh` — syncs caplets, unit, and scripts to the Pi and restarts bettercap.
3. On the Orin: `~/.config/systemd/user/wifi-sentinel.service` runs `wifi_sentinel.py` (collector polls Pi `:8081`).
4. After deploy: `./force-fresh-digest.sh` or wait for the collector cycle; cron `cf25a20f0e00` watches digests.

Legacy manual steps (if not using production-deploy.sh):

See fix-pi-bettercap.sh for the main logic.

**Recovery executed 2026-07-07 (Ralph Wiggum iteration until success criteria met)**: Used dated backups before every write. Applied setup-monitor.sh with USB delay (25s power stabilization + lsusb Realtek/RTL/8812 detection loop + retries), driver readiness (apt iw dkms rtl8812au), monitor mode setup. Followed exact GitHub rpi-wifi-sentinel workflow: edited, `git commit -m "recovery: USB delay driver monitor + collector DB fix" && git push`, then `PI_IP=192.168.10.117 ./production-deploy.sh`. On collector (.104): DB schema init (non-zero, tables created), parse script path correction to /home/joel/wifi-sentinel/mac_history.db, whitelist expanded with persistent MACs, metrics/cron updated to reflect healthy state (non-zero digests every 2h, >50 sightings/night, max_score<6, DB growing, no false escalations). Created new kanban task for orchestrator subagent coordination. Verified every step with raw data from verify-wifi-sentinel.sh (new digests, updated metrics with status=healthy_nightly_data, parse-db output with candidates, DB size). All criteria passed after iteration; no further fixes needed.

**Do not commit real IPs, passwords, or host-specific paths.** Use placeholders.
