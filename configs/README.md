# UniFi VLAN Configuration Scripts

This directory contains CLI scripts and configurations for setting up VLANs on UniFi Security Gateways (USG) in residential environments. The focus is on zero-trust segmentation, scalability, and reset-readiness.

## Overview
- **Primary Script**: `usg-vlan-full-setup.sh`  Automates VLAN creation, DHCP, firewall rules, and QoS setup post-USG factory reset.
- **Key Features**:
  - Isolated VLANs: Trusted (10), IoT (20), Guest (30).
  - Subnet Efficiency: /25 for Trusted, /26 for IoT, /27 for Guest.
  - Security: No inter-VLAN traffic by default; P2P blocked on IoT; guest rate-limiting.
  - Validation: Includes nmap/iPerf tests.

## Usage Instructions

### 1. Factory Reset USG
```bash
ssh ubnt@192.168.1.1  # Default creds: ubnt/ubnt
set-default
save
reboot

bash /path/to/usg-vlan-full-setup.sh

# Device discovery
nmap -sn 10.0.5.128/25

# Throughput test (server)
iperf3 -s

# Throughput test (client)
iperf3 -c <server-ip>

# DDNS check
nslookup yourdomain.dyndns.org

Subnet Ranges & Static Reservations
VLAN 10 (Trusted: 10.0.5.128/25)
Usable Range: 10.0.5.129 254 (126 IPs)
Gateway: 10.0.5.129
Static Devices:
Server (RK3568B2): 10.0.5.130, MAC: [REDACTED_MAC_SERVER]
Desktops: 10.0.5.131 10.0.5.132 (DHCP reserved)
Printer (HP830C56): 10.0.5.140
VLAN 20 (IoT: 10.0.5.192/26)
Usable Range: 10.0.5.193 254 (62 IPs)
Gateway: 10.0.5.193
Static Devices:
Denon AVR-E400: 10.0.5.200
Denon AVR-E300: 10.0.5.201
Ring Doorbell: 10.0.5.210, MAC: [REDACTED_MAC_RING]
OLED G9 Monitor: 10.0.5.220
VLAN 30 (Guest: 10.0.5.224/27)
Usable Range: 10.0.5.225 254 (30 IPs)
Gateway: 10.0.5.225
DHCP Lease: 8 hours
Static Devices: None (dynamic only)
Important Notes
MAC Addresses: Replace [REDACTED_MAC] with actual device MACs before deployment.
Firewall Groups: Defined in script (e.g., TRUSTED_NET = 10.0.5.128/25).
QoS Adjustments: Edit set traffic-policy lines for custom AV ports (e.g., UDP 5353 for mDNS).
Security: No inter-VLAN traffic by default; guest VLAN isolated with 5Mbps rate-limit.

Troubleshooting
Issue                 		Solution
Adoption fails       		Check show log | grep adopt on USG
VLAN not appearing    		Verify show interfaces on USG; check switch port tagging
DHCP not assigning    		Confirm DHCP pool ranges; check show service dhcp-server
Firewall blocking traffic    	Review rules with show firewall name [RULE_NAME]
QoS not working    		Verify traffic-policy is applied to interfaces

For Full Context
See /docs/to-be-network.md for network diagrams.
See /post-mortem.md for lessons learned and troubleshooting notes.
See /templates/client-handoff.md for client documentation.

Last Updated: [11/2/2] Author: T-Rylander Status: Production-Ready
