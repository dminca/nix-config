# qBittorrent and Prowlarr on Yggdrasil

Diataxis type: How-to guide

Use this guide when qBittorrent and Prowlarr cannot find useful peers over the default path and you want to route them over Yggdrasil.

## Prerequisites

1. Yggdrasil service can be enabled on the media LXC host.
2. qBittorrent can bind to a specific interface.
3. LXC networking and firewall rules allow Yggdrasil traffic.

## Steps

### 1. Enable Yggdrasil

Add a Yggdrasil configuration to the target host module:

```nix
services.yggdrasil = {
  enable = true;
  config = {
    Peers = [
      # Add peers in the format "tls://ip:port"
    ];
    InterfaceNonce = "";
  };
};
```

### 2. Bind qBittorrent to the Yggdrasil interface

Configure qBittorrent to bind traffic to `tun0`:

```nix
services.qbittorrent = {
  serverConfig = {
    Preferences = {
      SavePath = "/mnt/arr-data/downloads/complete";
      TempPath = "/mnt/arr-data/downloads/incomplete";
      TempPathEnabled = true;
      Connection = {
        Interface = "tun0";
      };
    };
  };
};
```

### 3. Align Prowlarr network path

Ensure Prowlarr follows the same network path, either by binding/listening on the Yggdrasil address or by using an explicit proxy path that uses Yggdrasil.

```nix
services.prowlarr = {
  # Keep existing service config.
  # Ensure listen/proxy settings use the Yggdrasil network path.
};
```

### 4. Validate connectivity

Run:

```sh
ip addr
```

Confirm the Yggdrasil address exists and `tun0` is up.

## Troubleshooting

- Verify the container can reach at least one Yggdrasil peer.
- Verify firewall rules allow the required ports on `tun0`.
- If there are no peers configured, Yggdrasil will not establish a usable network.

