#!/bin/bash
# ---------------------------------------------
# Post-Install Networking Fix for LAN Access
# Configures IP forwarding and NAT masquerading
# ---------------------------------------------

echo "Enabling IPv4 forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo sed -i 's/^#\?net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf

echo "Applying NAT masquerade rule on default interface..."
DEFAULT_IF=$(ip route show default | awk '{print $5}' | head -n1)
sudo iptables -t nat -C POSTROUTING -o "$DEFAULT_IF" -j MASQUERADE 2>/dev/null || \
sudo iptables -t nat -A POSTROUTING -o "$DEFAULT_IF" -j MASQUERADE

sudo apt install -y netfilter-persistent
sudo netfilter-persistent save

echo "Restarting WireGuard interface..."
sudo systemctl restart wg-quick@wg0

echo "Routing configuration completed."
exit 0
