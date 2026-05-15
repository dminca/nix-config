# *arr media stack day-0 setup - resources

> how many resources are required, which one requires VPN?

## Resources & Proxmox settings

**LXC (qBittorrent + Prowlarr):**
- **CPU:** 2 cores
- **RAM:** 4GB (qBittorrent can use more if handling many torrents)
- **Storage:** Direct passthrough to ZFS pool for downloads
- **Network:** Bridged, VPN routed
- **Settings:**
  - Enable `privileged: true` for qBittorrent (needed for port forwarding, filesystem access)
  - Set `nesting: true` if using Docker inside LXC
  - Assign static IP

**VM (Radarr, Sonarr, Bazarr, Jellyfin):**
- **CPU:** 4 cores (Jellyfin transcoding benefits from more)
- **RAM:** 8GB (Jellyfin + *arr services)
- **Storage:** ZFS dataset mount for media
- **GPU:** Pass through Intel iGPU to VM for Jellyfin hardware acceleration
- **Settings:**
  - Enable `hardware: virtio` for GPU passthrough
  - Set `cpu: host` for Jellyfin (better transcoding performance)
  - Allocate 1GB VRAM to VM if using iGPU

**Shared:**
- Use `virtio` for disk and network for best performance
- Enable `discard: on` for ZFS thin provisioning
- Set `swap: 1GB` for LXC, `swap: 2GB` for VM

## VPN requirement

- Prowlarr manages indexers. qBittorrent handles downloads. Both are required. Route both through the VPN
