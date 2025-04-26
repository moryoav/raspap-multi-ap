#!/bin/bash

IFACE=wlan2
CFG=/etc/wpa_supplicant/wpa_supplicant.conf
LOG=/var/log/wpa_autoconnect.log

# 1) Rotate the log: keep only last 100 lines if it exists
if [ -f "$LOG" ]; then
  tail -n100 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi

# 2) Give raspap-post-boot.sh time to finish (config + IPs + iptables)
sleep 30

# 3) Clean up any stale socket or old wpa_supplicant on this iface
rm -f /var/run/wpa_supplicant/"$IFACE"*
pkill -f "wpa_supplicant.*-i $IFACE" || true

# 4) Launch the client using whatever’s now in the dynamic config
/usr/sbin/wpa_supplicant -B -Dnl80211 \
  -c "$CFG" -i "$IFACE" \
  >> "$LOG" 2>&1
