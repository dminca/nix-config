# qBittorrent and Prowlarr on yggdrasil network

> in case there aren't any peers to connect qBittorrent or Prowlarr to, one
can easily switch to using the yggdrasil net

## Key Requirements

1. **Yggdrasil service enabled** on the LXC container (md-nixos-02)
2. **Bind qBittorrent & Prowlarr to Yggdrasil's interface** (usually `tun0` by default)
3. **Network access from LXC container to Yggdrasil peers** (may need to configure LXC network settings)

## Configuration for md-nixos-02

Add to sneeky.nix:

```nix
# Enable Yggdrasil service
services.yggdrasil = {
  enable = true;
  config = {
    Peers = [
      # Add your Yggdrasil peers here
      # Format: "tls://ip:port"
    ];
    InterfaceNonce = ""; # Leave empty for random
  };
};

# Bind qBittorrent to Yggdrasil interface
services.qbittorrent = {
  # ... existing config ...
  serverConfig = {
    Preferences = {
      SavePath = "/mnt/arr-data/downloads/complete";
      TempPath = "/mnt/arr-data/downloads/incomplete";
      TempPathEnabled = true;

      # Bind to Yggdrasil interface
      Connection = {
        Interface = "tun0"; # Yggdrasil's interface
      };
    };
  };
};

# Bind Prowlarr to Yggdrasil (via proxy or interface binding)
services.prowlarr = {
  # ... existing config ...
  # Prowlarr may need to listen on Yggdrasil's IP
};
```

## Important Considerations

- **LXC networking**: Verify the container can access Yggdrasil peers (may need raw socket access or specific LXC device settings)
- **Firewall rules**: Open Prowlarr/qBittorrent ports on the Yggdrasil interface
- **Peer discovery**: Configure Yggdrasil peers; without them, the network won't connect
- **IP assignment**: After enabling Yggdrasil, run `ip addr` to find the Yggdrasil IPv6 address

