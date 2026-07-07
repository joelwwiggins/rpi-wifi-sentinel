#!/bin/bash
LOG=~/wifi-sentinel/logs/usb-monitor-watcher-$(date +%Y%m%d_%H%M%S).log
mkdir -p ~/wifi-sentinel/logs
echo "=== USB WiFi Monitor Watcher Started $(date) ===" | tee -a $LOG
echo "max_usb_current=1 is set. Waiting for RTL8812AU / wlan1 after plug-in. 25s power delay will trigger only for USB path." | tee -a $LOG
for i in {1..600}; do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 joel@${PI_IP:-192.168.10.117} 'lsusb | grep -E "0bda:8812|Realtek|RTL8812"' > /dev/null 2>&1 || ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 joel@${PI_IP:-192.168.10.117} 'ip -br link | grep wlan1' > /dev/null 2>&1; then
    echo "[$(date)] USB adapter detected - triggering fix with power delay" | tee -a $LOG
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 joel@${PI_IP:-192.168.10.117} '
      cd /home/joel/wifi-sentinel
      sudo systemctl stop bettercap.service || true
      sudo bash ./fix-pi-bettercap.sh
    ' 2>&1 | tee -a $LOG
    echo "Post-fix verification:" | tee -a $LOG
    ssh -o StrictHostKeyChecking=no joel@${PI_IP:-192.168.10.117} 'ip -br link; lsusb; ss -tlnp | grep 8081; curl -s --max-time 5 http://127.0.0.1:8081/api/session | head -c 150' 2>&1 | tee -a $LOG
    echo "USB monitor should now be active on wlan1mon with management on wlan0 stable." | tee -a $LOG
    break
  fi
  sleep 3
done
echo "Watcher completed. Check $LOG. If dongle still not seen, install 8812au-dkms driver." | tee -a $LOG
