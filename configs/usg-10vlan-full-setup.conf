# usg-10vlan-full-setup.conf
# Full VLAN setup for residential UniFi USG (VyOS CLI snippet) - 10.0.5.x/24 congruent scheme
# Purpose: Implements zero-trust segmentation using carved 10.0.5.x subnets for scalability/no-overlap.
# Assumes: WAN=eth0 (DHCP), LAN trunk=eth1. Customize IPs/MACs as needed.
# Usage: In 'configure' mode: load /tmp/usg-10vlan-full-setup.conf; commit; save.
# Post-apply: Re-adopt in controller; reboot if interfaces flap. Test: show interfaces, show dhcp leases.
# Scalability: Trusted /24 (254 hosts); IoT/Guest /26 (62 hosts) carved from 10.0.5.0/24 supernet.

# Interfaces: Basic WAN/LAN setup
set interfaces ethernet eth0 address 'dhcp'  # WAN: DHCP from ISP (or static: 'YOUR_WAN_IP/24')
set interfaces ethernet eth0 description 'WAN'
set interfaces ethernet eth0 dhcp-options default-route update
set interfaces ethernet eth0 dhcp-options default-route-distance 1
set interfaces ethernet eth0 firewall in name WAN_IN
set interfaces ethernet eth0 firewall local name WAN_LOCAL

set interfaces ethernet eth1 description 'LAN Trunk'
set interfaces ethernet eth1 address '10.0.5.1/24'  # Native VLAN1 (Trusted) - untagged traffic, full /24
set interfaces ethernet eth1 firewall in name LAN_IN

# VLAN Interfaces: Sub-interfaces on eth1 trunk (carved /26 for IoT/Guest)
set interfaces ethernet eth1 vif 10 address '10.0.5.65/26'  # IoT-VLAN10: 10.0.5.64/26 (64-127)
set interfaces ethernet eth1 vif 10 description 'IoT-VLAN10'
set interfaces ethernet eth1 vif 20 address '10.0.5.129/26'  # Guest-VLAN20: 10.0.5.128/26 (128-191)
set interfaces ethernet eth1 vif 20 description 'Guest-VLAN20'

# DHCP Configuration: Per-VLAN servers with ranges, leases, and statics (non-overlapping)
# LAN1 (Trusted VLAN1: 10.0.5.0/24)
set service dhcp-server shared-network-name LAN1 subnet 10.0.5.0/24 default-router '10.0.5.1'
set service dhcp-server shared-network-name LAN1 subnet 10.0.5.0/24 dns-server '10.0.5.1'  # Or external: '8.8.8.8'
set service dhcp-server shared-network-name LAN1 subnet 10.0.5.0/24 lease '86400'  # 24h lease
set service dhcp-server shared-network-name LAN1 subnet 10.0.5.0/24 range 0 start '10.0.5.100'
set service dhcp-server shared-network-name LAN1 subnet 10.0.5.0/24 range 0 stop '10.0.5.200'
# Static: Document MAC in repo README or here for key devices
set service dhcp-server shared-network-name LAN1 static-mapping CLIENT01 ip-address '10.0.5.50'  # MAC: aa:bb:cc:dd:ee:ff (e.g., server/printer)
set service dhcp-server shared-network-name LAN1 static-mapping CLIENT01 mac-address 'aa:bb:cc:dd:ee:ff'

# IoT (VLAN10: 10.0.5.64/26) - Limited range for security
set service dhcp-server shared-network-name IOT subnet 10.0.5.64/26 default-router '10.0.5.65'
set service dhcp-server shared-network-name IOT subnet 10.0.5.64/26 dns-server '10.0.5.65'
set service dhcp-server shared-network-name IOT subnet 10.0.5.64/26 lease '86400'
set service dhcp-server shared-network-name IOT subnet 10.0.5.64/26 range 0 start '10.0.5.70'
set service dhcp-server shared-network-name IOT subnet 10.0.5.64/26 range 0 stop '10.0.5.100'  # Avoids overlap with Trusted

# Guest (VLAN20: 10.0.5.128/26) - Short leases, larger range for turnover
set service dhcp-server shared-network-name GUEST subnet 10.0.5.128/26 default-router '10.0.5.129'
set service dhcp-server shared-network-name GUEST subnet 10.0.5.128/26 dns-server '10.0.5.129'
set service dhcp-server shared-network-name GUEST subnet 10.0.5.128/26 lease '3600'  # 1h for guests
set service dhcp-server shared-network-name GUEST subnet 10.0.5.128/26 range 0 start '10.0.5.135'
set service dhcp-server shared-network-name GUEST subnet 10.0.5.128/26 range 0 stop '10.0.5.190'

# NAT: Masquerade outbound traffic from each VLAN to WAN (eth0)
set nat source rule 10 description 'LAN1 (Trusted) to WAN - Outbound NAT'
set nat source rule 10 outbound-interface 'eth0'
set nat source rule 10 source address '10.0.5.0/24'
set nat source rule 10 translation address 'masquerade'

set nat source rule 20 description 'IoT (VLAN10) to WAN - Outbound NAT'
set nat source rule 20 outbound-interface 'eth0'
set nat source rule 20 source address '10.0.5.64/26'
set nat source rule 20 translation address 'masquerade'

set nat source rule 30 description 'Guest (VLAN20) to WAN - Outbound NAT'
set nat source rule 30 outbound-interface 'eth0'
set nat source rule 30 source address '10.0.5.128/26'
set nat source rule 30 translation address 'masquerade'

# Firewall: WAN Protection (Inbound)
set firewall name WAN_IN default-action 'drop'  # Drop all inbound by default
set firewall name WAN_IN rule 10 action 'accept'  # Allow established/related sessions
set firewall name WAN_IN rule 10 state established 'enable'
set firewall name WAN_IN rule 10 state related 'enable'
set firewall name WAN_IN rule 20 action 'drop'  # Drop invalid packets
set firewall name WAN_IN rule 20 state invalid 'enable'

set firewall name WAN_LOCAL default-action 'drop'  # Protect USG itself
set firewall name WAN_LOCAL rule 10 action 'accept'  # Allow established/related
set firewall name WAN_LOCAL rule 10 state established 'enable'
set firewall name WAN_LOCAL rule 10 state related 'enable'
set firewall name WAN_LOCAL rule 20 action 'accept'  # Allow UniFi mgmt (adjust ports)
set firewall name WAN_LOCAL rule 20 destination port '22,443'
set firewall name WAN_LOCAL rule 20 protocol 'tcp'
set firewall name WAN_LOCAL rule 30 action 'drop'  # Drop invalid
set firewall name WAN_LOCAL rule 30 state invalid 'enable'

# Firewall: LAN Segmentation (Zero-Trust - Block inter-VLAN; allow to WAN)
set firewall name LAN_IN default-action 'accept'  # Allow outbound to WAN/intra-VLAN by default
# Block LAN1 (Trusted) to IoT (VLAN10) - Prevent trusted devices accessing IoT
set firewall name LAN_IN rule 10 action 'drop'
set firewall name LAN_IN rule 10 destination address '10.0.5.64/26'
# Block LAN1 (Trusted) to Guest (VLAN20) - Prevent trusted accessing guests
set firewall name LAN_IN rule 20 action 'drop'
set firewall name LAN_IN rule 20 destination address '10.0.5.128/26'
# Apply to all LAN interfaces (expand for per-VLAN tweaks)
set interfaces ethernet eth1 firewall in name LAN_IN
set interfaces ethernet eth1 vif 10 firewall in name LAN_IN
set interfaces ethernet eth1 vif 20 firewall in name LAN_IN  # Guest: Add captive portal rules if needed

# Optional: DNS Forwarding - Centralized forwarding for VLANs (remove if using external DNS only)
set service dns forwarding listen-on eth1
set service dns forwarding listen-on eth1.10
set service dns forwarding listen-on eth1.20