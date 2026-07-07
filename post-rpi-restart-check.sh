#!/bin/bash
set -e
echo "=== Post-RPi Restart Validation (run on Orin after Pi is up) ==="
echo "Current time: $(date)"
echo "1. Discover Pi reachability"
for ip in "${PI_IP:-192.168.10.117}" "100." "${HOMELAB_PREFIX:-192.168.20.}"; do
  echo "Testing $ip range..."
  ping -c 2 -W 2 $ip 2>&1 | tail -3 || true
done
echo "2. Tailscale peers:"
tailscale status | grep -E "pi|rpi|117" || echo "No obvious Pi in tailscale"
echo "3. Run this on the Pi itself first: cd ~/wifi-sentinel && sudo ./fix-pi-bettercap.sh"
echo "Then from here, update if needed and test API."
echo "Run manually after Pi fix."

