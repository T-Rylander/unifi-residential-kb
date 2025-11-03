graph TD
    A[Modem: CGM4331COM] --> B[Gateway: USG + DDNS]
    B --> C[Switch: US-8-60W]
    C --> D[APs: UAP-CA-LITE x2]
    C --> E[Server: RK3568B2 (Docker Controller)]
    subgraph VLAN10 ["Trusted (VLAN 10)"]
        F[Desktops x2]
        G[Printer: HP830C56]
    end
    subgraph VLAN20 ["IoT (VLAN 20)"]
        H[Denons x2]
        I[Ring Doorbell]
        J[Odyssey OLED]
    end
    subgraph VLAN30 ["Guest (VLAN 30)"]
        K[Guests]
    end
    C --> VLAN10
    C --> VLAN20
    C --> VLAN30
    style B fill:#ccffcc  // Secure
