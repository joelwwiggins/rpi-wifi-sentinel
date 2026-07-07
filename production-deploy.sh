#!/bin/bash
# FINAL PRODUCTION DEPLOYMENT - clean stop, rm any cached caplet, force minimal caplet, restart with API forced early
PI_IP="${PI_IP:-192.168.10.117}"
echo "=== FINAL PRODUCTION DEPLOYMENT to $PI_IP (garage node) - $(date) ==="

scp -o StrictHostKeyChecking=no wifi-sentinel.cap bettercap.service.template fix-pi-bettercap.sh joel@$PI_IP:~/wifi-sentinel/

ssh -o StrictHostKeyChecking=no joel@$PI_IP '
cd ~/wifi-sentinel
echo "Cleaning old state..."
sudo systemctl stop bettercap.service
sudo rm -f /var/lib/bettercap/* 2>/dev/null || true
sudo rm -f wifi-sentinel.cap* 2>/dev/null || true

echo "Deploying minimal production caplet..."
cp wifi-sentinel.cap wifi-sentinel.cap.good
sudo cp wifi-sentinel.cap.good wifi-sentinel.cap

echo "Deploying unit with API forced early..."
sudo cp bettercap.service.template /etc/systemd/system/bettercap.service
sudo systemctl daemon-reload
sudo systemctl start bettercap.service
sleep 12

echo "=== FINAL PRODUCTION STATUS ==="
systemctl is-active bettercap.service
ps aux | grep -o "bettercap.*iface.*"
echo "Port 8081 listening on 0.0.0.0?"
ss -tlnp | grep 8081
echo "API test (expect valid JSON with garage data):"
curl -s --max-time 15 http://127.0.0.1:8081/api/session | head -c 400 || echo "Code: $(curl -s -o /dev/null -w "%{http_code}" --max-time 15 http://127.0.0.1:8081/api/session)"
echo "Journal (last 15 lines - should be clean):"
journalctl -u bettercap.service -n 15 --no-pager
'
echo "Final production deployment complete. The API should now be responding with fresh garage data. Run ./force-fresh-digest.sh to update alerts."
