#!/bin/bash
# Production deployment script for RPi WiFi Sentinel (garage node)
PI_IP="${PI_IP:-192.168.10.117}"
echo "Deploying latest from repo to $PI_IP..."

scp -o StrictHostKeyChecking=no wifi-sentinel.cap fix-pi-bettercap.sh setup-monitor.sh usb-monitor-watcher.sh bettercap.service.template joel@$PI_IP:~/wifi-sentinel/

ssh -o StrictHostKeyChecking=no joel@$PI_IP '
  cd ~/wifi-sentinel
  cp wifi-sentinel.cap wifi-sentinel.cap.good
  sudo cp bettercap.service.template /etc/systemd/system/bettercap.service
  sudo systemctl daemon-reload
  sudo systemctl restart bettercap.service
  echo "Deployment complete. Service status:"
  systemctl is-active bettercap.service
  echo "Running iface:"
  ps aux | grep -o "bettercap.*iface.*"
'
echo "Production deployment finished. Run ./force-fresh-digest.sh to verify new garage data."
