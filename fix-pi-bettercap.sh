#!/bin/bash
set -e
LOG=/home/joel/wifi-sentinel/logs/fix-$(date +%Y%m%d_%H%M%S).log
mkdir -p /home/joel/wifi-sentinel/logs /home/joel/wifi-sentinel/handshakes
echo "[$(date)] === Production Fix - Light Pre for ExecStartPre ===" | tee -a $LOG

# Quick backup
cp wifi-sentinel.cap wifi-sentinel.cap.bak.$(date +%s) 2>/dev/null || true

# Check for USB adapter (wlan1 OR already renamed wlan1mon)
if ip link show wlan1mon >/dev/null 2>&1 || ip link show wlan1 >/dev/null 2>&1; then
  echo "USB adapter detected (wlan1 or wlan1mon) - using monitor interface" | tee -a $LOG
  TARGET_IFACE="wlan1mon"
  # 25s power delay ONLY for USB path (critical for max_usb_current=1)
  echo "Applying 25s power stabilization delay for USB adapter..." | tee -a $LOG
  sleep 25
else
  echo "No USB adapter detected - falling back to wlan0 management (recon disabled)" | tee -a $LOG
  TARGET_IFACE="wlan0"
fi

# Deploy clean production caplet (cap.good is canonical in repo; fall back to wifi-sentinel.cap)
CAP_SRC="wifi-sentinel.cap.good"
if [ ! -f "$CAP_SRC" ]; then
  echo "WARN: $CAP_SRC missing — using wifi-sentinel.cap from deploy" | tee -a $LOG
  CAP_SRC="wifi-sentinel.cap"
fi
cp "$CAP_SRC" wifi-sentinel.cap
sed -i "s|set wifi.interface .*|set wifi.interface $TARGET_IFACE|" wifi-sentinel.cap

# Ensure API lines exist (dedupe-safe: prepend only if port line absent)
if ! grep -q 'api.rest.port 8081' wifi-sentinel.cap; then
  sed -i "1i set api.rest on\nset api.rest.address 0.0.0.0\nset api.rest.port 8081" wifi-sentinel.cap
fi

if [ "$TARGET_IFACE" = "wlan1mon" ]; then
  sed -i "s|^# wifi.recon on.*|wifi.recon on|" wifi-sentinel.cap
  sed -i "s|^# wifi.probe on.*|wifi.probe on|" wifi-sentinel.cap
elif [ "$TARGET_IFACE" = "wlan0" ]; then
  sed -i "s|^wifi.recon on|# wifi.recon on (disabled on wlan0 to prevent link drop)|" wifi-sentinel.cap
  sed -i "s|^wifi.probe on|# wifi.probe on (disabled on wlan0 to prevent link drop)|" wifi-sentinel.cap
fi

sudo -S -p '' chown -R joel:joel /home/joel/wifi-sentinel/logs /home/joel/wifi-sentinel/handshakes 2>/dev/null || true
chmod +x *.sh 2>/dev/null || true

echo "Production caplet deployed for $TARGET_IFACE. Pre complete." | tee -a $LOG
echo "[$(date)] Fix complete - management on wlan0 stable, recon on wlan1mon when available" | tee -a $LOG
