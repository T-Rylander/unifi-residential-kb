# As-Is Network Diagram

Current topology: Modem  USG  Switch  Endpoints (spaghetti cabling risks).

```mermaid
graph TD
    A[Modem: CGM4331COM] --> B[Gateway: USG]
    B --> C[Switch: US-8-60W]
    C --> D[APs: UAP-CA-LITE x2]
    C --> E[Server: RK3568B2]
    C --> F[Desktops x2 + Printer]
    C --> G[IoT: Denons x2, Ring, OLED]
    H[Cloud Key: UC-CK (Faulty)] -.-> B
    style B fill:#ffcccc  // High Risk
    style H fill:#ffcccc
 No VLANs; potential 50% throughput loss from unlabeled runs.
