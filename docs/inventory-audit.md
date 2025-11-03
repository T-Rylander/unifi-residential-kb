# Inventory Audit

Compliant audit of 13-device residential setup. Anonymized MACs/IPs per CCPA/GDPR.

| Device          | Model       | MAC (Redacted) | Role          | Firmware | Risk (e.g., CVE) | Action                  | Notes                  |
|-----------------|-------------|----------------|---------------|----------|------------------|-------------------------|------------------------|
| Wireless AP    | UAP-CA-LITE | [REDACTED]    | Access Point | 4.x     | Medium          | Firmware update        | 2 units               |
| UniFi Cloud Key| UC-CK       | [REDACTED]    | Controller   | N/A     | High (non-func) | Migrate to Docker      | Not functioning       |
| Gateway        | USG         | [REDACTED]    | Edge Routing | 4.4.x   | High (exploits) | Update + DDNS config   | Firmware pending      |
| Switch         | US-8-60W    | [REDACTED]    | Layer 2      | 4.x     | Low             | VLAN provisioning      |                       |
| Modem          | CGM4331COM  | [REDACTED]    | ISP Handoff  | N/A     | Low             | Bridge mode verify     |                       |
| Server         | RK3568B2    | [REDACTED]    | Host         | N/A     | Low             | Controller fallback    |                       |
| Desktop PCs    | N/A         | [REDACTED]    | Endpoints    | N/A     | Low             | VLAN 10 (Trusted)      | 2 units               |
| Printer        | HP830C56    | [REDACTED]    | Peripheral   | N/A     | Low             | VLAN 10                |                       |
| IoT (AVR)      | Denon E400  | [REDACTED]    | Media        | N/A     | Medium (IoT)    | VLAN 20 (Segmented)    |                       |
| IoT (AVR)      | Denon E300  | [REDACTED]    | Media        | N/A     | Medium (IoT)    | VLAN 20                |                       |
| IoT (Monitor)  | 49in G9     | [REDACTED]    | Display      | N/A     | Low             | VLAN 20                | Odyssey OLED          |
| IoT (Doorbell) | Ring        | [REDACTED]    | Security     | N/A     | High (Cloud)    | VLAN 20 + Firewall     |                       |

**Risk Summary**: High focus on USG/Cloud Key; IoT segmentation to prevent lateral movement.
