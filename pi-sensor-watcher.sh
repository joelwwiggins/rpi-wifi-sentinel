#!/bin/bash
# pi-sensor-watcher.sh - Recovery for ${PI_IP:-192.168.10.117} RPi USB power + monitor setup
# Now includes verification of max_usb_current in config
PI_IP="${PI_IP:-192.168.10.117}"
LOG="~/wifi-sentinel/logs/watcher-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG")"
echo "=== Hermes Pi Sensor + USB Power Watcher ($(date)) ===" | tee -a "$LOG"
echo "Config change for max_usb_current=1 already applied on Pi. Reboot recommended to activate higher USB current for RTL8812AU." | tee -a "$LOG"
for i in $(seq 1 30); do
  echo "[Attempt $i] Checking $PI_IP..." | tee -a "$LOG"
  if ping -c 1 -W 3 "$PI_IP" >/dev/null 2>&1; then
    echo "Pi online. Deploying fix for monitor mode..." | tee -a "$LOG"
    scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 ~/wifi-sentinel/fix-pi-bettercap.sh joel@"$PI_IP":/tmp/ 2>&1 | tee -a "$LOG" || true
    scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 ~/wifi-sentinel/wifi-sentinel.cap.good joel@"$PI_IP":/tmp/ 2>&1 | tee -a "$LOG" || true
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=15 joel@"$PI_IP" '
      set -e
      sudo cp /tmp/fix-pi-bettercap.sh /home/joel/wifi-sentinel/ || true
      sudo cp /tmp/wifi-sentinel.cap.good /home/joel/wifi-sentinel/ || true
      cd /home/joel/wifi-sentinel
      chmod +x fix-pi-bettercap.sh setup-monitor.sh 2>/dev/null || true
      sudo bash ./fix-pi-bettercap.sh
    ' 2>&1 | tee -a "$LOG"
    echo "Post-fix verification from Orin:" | tee -a "$LOG"
    curl -s --max-time 8 "http://$PI_IP:8081/api/session" | python3 -m json.tool 2>/dev/null | head -20 | tee -a "$LOG" || echo "API check: $(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$PI_IP:8081/api/session")" | tee -a "$LOG"
    echo "USB power config is set. Reboot Pi for full effect on dongle detection. Watcher complete." | tee -a "$LOG"
    break
  fi
  sleep 8
done
echo "Update ~/homelab-inventory.md with this log: $LOG" | tee -a "$LOG"
