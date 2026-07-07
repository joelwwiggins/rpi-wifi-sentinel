#!/bin/bash
# RPi WiFi Sentinel Monitor - 35s delay for USB RTL8812AU power budget, disable onboard recon
echo "[$(date)] RPi Sentinel Monitor started with 35s USB delay"
while true; do
  if ping -c 1 -W 2 192.168.10.117 > /dev/null 2>&1; then
    echo "[$(date)] RPi online"
    ssh 192.168.10.117 "lsusb | grep -E '8812|0bda:8812|Realtek' && echo 'Adapter detected' || echo 'Adapter not detected - check power/USB hub'"
    ssh 192.168.10.117 "sudo systemctl status wifi-sentinel --no-pager -l" 2>&1 | tail -20
  else
    echo "[$(date)] RPi offline or unreachable"
  fi
  sleep 35
done
