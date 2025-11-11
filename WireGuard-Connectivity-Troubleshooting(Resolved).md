*Created as part of home lab documentation – shared for educational purposes.*

### Scenario

After rebooting my Raspberry Pi / ISP modem, WireGuard clients could no longer access the internet through the VPN, though **local services (Pi-hole dashboard, etc.)** still worked.

---

## Symptoms

- `sudo wg show` displayed peers but **no “latest handshake”** or very low transfer numbers (`58 KiB / 2 KiB`).
- Could access **local domains** like `pi.hole` quickly.
- **External websites / apps** hung or timed-out.
- Public IP on client did **not** match home IP.

---

## Root Cause Analysis

1. **ISP modem reboot → new public IP.**
    
    Clients pointed to the old IP → no handshake.
    
2. **After reconnection → no NAT / IP-forwarding** on Pi, so packets from `wg0` never reached the internet.
3. Once forwarding + masquerade were restored, traffic flowed normally.

---

## Troubleshooting Steps & Commands

### 1. Check service status

```bash
sudo systemctl status wg-quick@wg0
sudo wg show
```

→ If active but no handshake → client can’t reach server.

---

### 2. Verify server listening

```bash
sudo ss -ulpn | grep 51820
```

Should show UDP :51820 bound to `wg`.

---

### 3. Confirm network and IP

```bash
hostname -I      # Pi’s LAN IP
ip a | grep wg0  # VPN interface IP
```

---

### 4. Restart interfaces cleanly

```bash
sudo wg-quick down wg0
sudo wg-quick up wg0
```

(Optional)

```bash
sudo systemctl restart networking
```

---

### 5. Check NAT / forwarding

Enable forwarding:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl --system
```

Add masquerade rule (replace `<NETWORK_INTERFACE>` if needed):

```bash
sudo iptables -t nat -A POSTROUTING -o <NETWORK_INTERFACE> -j MASQUERADE
sudo apt install netfilter-persistent -y
sudo netfilter-persistent save
```

Confirm:

```bash
sudo iptables -t nat -L POSTROUTING -v
```

---

### 6. Test connectivity

From client:

```bash
ping -c 4 <WG_SERVER_IP>     # Tunnel reachability
ping -c 4 1.1.1.1         # Internet reachability
curl ifconfig.me          # Should show home public IP
```

---

### 7. Verify DNS

```bash
nslookup google.com
```

If it returns

`Address: Wiregaurd IP` → DNS queries hitting Pi-hole.

Check Pi-hole upstream:

```bash
cat /etc/pihole/setupVars.conf | grep DNS
sudo systemctl status unbound
```

---

## Resolutions Applied

- Updated client endpoint to new public IP.
- Enabled `net.ipv4.ip_forward=1`.
- Added `MASQUERADE` rule for `<NETWORK_INTERFACE>`.
- Saved iptables with `netfilter-persistent`.
- Verified DNS resolving through Pi-hole → Unbound.
- Confirmed full-tunnel browsing with correct public IP.
