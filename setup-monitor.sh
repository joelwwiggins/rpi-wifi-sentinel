#!/bin/bash
set -e
echo "[$(date)] Setting up wlan1mon (retries 1-4, with extended boot power delay + adapter detection loop)..."
# Extended delay for USB power negotiation on low-power Pi (Zero 2W or similar) - addresses power issue during boot
sleep 25
echo "Extended power stabilization delay complete. Waiting for USB adapter to enumerate..."
# Wait loop for USB adapter to appear in lsusb (up to 30s)
for i in {1..15}; do
  if lsusb | grep -E "Realtek|RTL|8812|0bda" > /dev/null; then
    echo "USB adapter detected on attempt $i"
    break
  fi
  echo "Waiting for USB adapter... attempt $i/15"
  sleep 2
done
echo "Detecting USB adapter complete. Proceeding with monitor setup..."
for i in {1..6}; do
  echo "Attempt $i..."
  sudo ip link set wlan1 down 2>/dev/null || true
  sudo nmcli device set wlan1 managed no 2>/dev/null || true
  
  # Put into monitor without killing other processes
  sudo iw dev wlan1 set type monitor 2>/dev/null || sudo /usr/sbin/iw dev wlan1 set type monitor || true
  sudo ip link set dev wlan1 name wlan1mon 2>/dev/null || true
  sudo ip link set wlan1mon up 2>/dev/null || true
  
  if ip -br link show wlan1mon > /dev/null 2>&1; then
    echo "SUCCESS: wlan1mon ready on attempt $i"
    exit 0
  fi
  sleep 6
done
echo "ERROR: Could not create wlan1mon after 6 attempts"
exit 1
