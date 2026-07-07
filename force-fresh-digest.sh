#!/bin/bash
# Production helper: Force a fresh digest from the Pi API after garage move
PI_IP="${PI_IP:-192.168.10.117}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DIGEST_DIR=~/wifi-sentinel/digests
mkdir -p $DIGEST_DIR

echo "=== Forcing fresh digest from garage sensor ($PI_IP) - $(date) ==="

curl -s --max-time 15 "http://$PI_IP:8081/api/session" > "$DIGEST_DIR/${TIMESTAMP}.json"

if [ -s "$DIGEST_DIR/${TIMESTAMP}.json" ]; then
  echo "Success: New digest written ($DIGEST_DIR/${TIMESTAMP}.json)"
  ls -lh "$DIGEST_DIR/${TIMESTAMP}.json"
  wc -l "$DIGEST_DIR/${TIMESTAMP}.json"
else
  echo "ERROR: Empty response from API. Check Pi service and network."
  echo "API HTTP code: $(curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8081/api/session")"
fi

echo "Latest digests:"
ls -lt $DIGEST_DIR | head -5
