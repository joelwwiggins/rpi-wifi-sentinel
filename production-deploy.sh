#!/bin/bash
PI_IP=${PI_IP:-192.168.10.117}
echo "Deploying to RPi at $PI_IP with 35s USB power delay for RTL8812AU"
scp setup-monitor.sh pi@$PI_IP:/home/pi/
ssh pi@$PI_IP "chmod +x /home/pi/setup-monitor.sh && sudo cp /home/pi/setup-monitor.sh /usr/local/bin/ && sudo systemctl restart wifi-sentinel || echo 'Service restart failed - check journal'"
echo "Deployment complete. Monitor with: ssh pi@$PI_IP \"journalctl -u wifi-sentinel -f\""
