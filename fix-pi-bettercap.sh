#!/bin/bash
set -e
# Run this on the Pi right after reboot while it's up
# Separates wlan0 (management) and wlan1mon (recon)
# Backs up before changes
# Safe - avoids killing NetworkManager on wlan0

LOG=/home/joel/wifi-sentinel/logs/fix-$(date +%Y%m%d_%H%M%S).log
mkdir -p /home/joel/wifi-sentinel/logs /home/joel/wifi-sentinel/handshakes

echo "[$(date)] === Starting Pi bettercap fix ===" | tee -a $LOG

# 1. Backup current configs
cp /home/joel/wifi-sentinel/wifi-sentinel.cap /home/joel/wifi-sentinel/wifi-sentinel.cap.bak.$(date +%s) 2>/dev/null || true
cp /etc/systemd/system/bettercap.service /home/joel/wifi-sentinel/bettercap.service.bak.$(date +%s) 2>/dev/null || true
echo "Backups created" | tee -a $LOG

# 2. Install required packages (safe, no remove)
sudo apt update
sudo apt install -y aircrack-ng iw ethtool || echo "Some packages may already be present"

# 3. Make sure USB adapter is detected as wlan1
echo "Current interfaces:"
ip -br link | tee -a $LOG

# 4. Prepare the recon interface safely (NO global airmon check kill)
if ip link show wlan1 >/dev/null 2>&1; then
  echo "USB adapter (wlan1) detected - setting up monitor mode" | tee -a $LOG
  
  sudo ip link set wlan1 down || true
  sudo nmcli device set wlan1 managed no 2>/dev/null || true
  
  # Put into monitor without killing other processes
  sudo iw dev wlan1 set type monitor 2>/dev/null || sudo /usr/sbin/iw dev wlan1 set type monitor || true
  sudo ip link set dev wlan1 name wlan1mon 2>/dev/null || true
  sudo ip link set wlan1mon up || true
  
  if ip link show wlan1mon >/dev/null 2>&1; then
    echo "SUCCESS: wlan1mon ready" | tee -a $LOG
    TARGET_IFACE=wlan1mon
  else
    echo "Failed to create wlan1mon, falling back to wlan0 for now" | tee -a $LOG
    TARGET_IFACE=wlan0
  fi
else
  echo "No USB adapter, using built-in wlan0 (will disrupt management if recon active)" | tee -a $LOG
  TARGET_IFACE=wlan0
fi

# Critical fix for management stability: disable wifi.recon/probe on wlan0 to prevent monitor mode from dropping the Orbi link
if [ "$TARGET_IFACE" = "wlan0" ]; then
  echo "wlan0 management-only mode - disabling wifi.recon and wifi.probe to maintain link" | tee -a $LOG
  sed -i 's|^wifi\.recon on|# wifi.recon on (disabled on wlan0 to prevent link drop)|' /home/joel/wifi-sentinel/wifi-sentinel.cap
  sed -i 's|^wifi\.probe on|# wifi.probe on (disabled on wlan0 to prevent link drop)|' /home/joel/wifi-sentinel/wifi-sentinel.cap || true
fi

# 5. Deploy clean caplet (wlan1mon for recon, API enabled)
cp /home/joel/wifi-sentinel/wifi-sentinel.cap.good /home/joel/wifi-sentinel/wifi-sentinel.cap
echo "Deployed clean caplet for $TARGET_IFACE" | tee -a $LOG

# Optional: update caplet interface if needed (sed already set to wlan1mon)
sed -i "s|set wifi.interface .*|set wifi.interface $TARGET_IFACE|" /home/joel/wifi-sentinel/wifi-sentinel.cap || true

# 6. Fix permissions
sudo chown -R joel:joel /home/joel/wifi-sentinel/logs /home/joel/wifi-sentinel/handshakes
chmod +x /home/joel/wifi-sentinel/*.sh 2>/dev/null || true

# 7. Restart bettercap with clean config
sudo systemctl stop bettercap || true
sleep 2
sudo systemctl daemon-reload || true

# Start with explicit iface for safety
sudo nohup /usr/bin/bettercap -iface $TARGET_IFACE -caplet /home/joel/wifi-sentinel/wifi-sentinel.cap > /home/joel/wifi-sentinel/logs/bettercap-live.log 2>&1 &
sleep 8

echo "bettercap started with iface $TARGET_IFACE" | tee -a $LOG

# 8. Verify
echo "=== Listening ports ===" | tee -a $LOG
ss -tuln | grep -E '22|8081' | tee -a $LOG

echo "=== API test (local) ===" | tee -a $LOG
curl -s --max-time 5 http://127.0.0.1:8081/api/session | head -c 500 | tee -a $LOG || echo "API not yet responding" | tee -a $LOG

echo "=== Journal tail ===" | tee -a $LOG
journalctl -u bettercap.service -n 10 --no-pager | tee -a $LOG || true

echo "[$(date)] === Fix script complete. Now test from Jetson: curl http://${PI_IP:-192.168.10.117}:8081/api/session ===" | tee -a $LOG
