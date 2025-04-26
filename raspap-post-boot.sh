#!/bin/bash
#
# /usr/local/bin/raspap-post-boot.sh
#
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# send stdout/stderr to root-writable log
exec >> /var/log/raspap-post-boot.log 2>&1
echo "=== raspap-post-boot.sh START $(date) ==="

# 1) give RaspAP ~30s to finish its own setup
sleep 30
echo "— waited 30s for RaspAP init"

# 2) ensure IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "ip_forward=1"

# 3) remove any old NAT on wlan1
iptables -t nat -D POSTROUTING -o wlan1 -j MASQUERADE 2>/dev/null && \
  echo "removed old NAT on wlan1"

# 4) add NAT on wlan2
iptables -t nat -A POSTROUTING -o wlan2 -j MASQUERADE
echo "added NAT on wlan2"

# 5) restart hostapd with both configs
systemctl stop hostapd.service
echo "stopped hostapd.service"
pkill hostapd 2>/dev/null && echo "killed leftover hostapd"
hostapd -B /etc/hostapd/wlan0.conf /etc/hostapd/wlan1.conf \
  && echo "hostapd started with dual APs" \
  || echo "ERROR: hostapd failed to start"

echo "=== raspap-post-boot.sh END $(date) ==="
