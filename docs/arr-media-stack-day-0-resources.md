# Arr Media Stack Day 0 Resources

Diataxis type: Reference

Use this page as a sizing and platform reference when creating the day-0 media stack on Proxmox.

## Resource Profile

### LXC (qBittorrent + Prowlarr)

- CPU: 2 cores
- RAM: 4 GB (increase for heavy torrent workloads)
- Storage: direct passthrough to ZFS pool for downloads
- Network: bridged, VPN-routed
- Proxmox settings:
	- `privileged: true` (required for some qBittorrent filesystem and networking use-cases)
	- `nesting: true` if running Docker inside the container
	- static IP assignment

### VM (Radarr, Sonarr, Bazarr, Jellyfin)

- CPU: 4 cores (more if transcoding is heavy)
- RAM: 8 GB
- Storage: ZFS dataset mounted for media
- GPU: Intel iGPU passthrough recommended for Jellyfin hardware acceleration
- Proxmox settings:
	- `hardware: virtio` for passthrough path
	- `cpu: host` for better transcoding performance
	- 1 GB vRAM allocation when using iGPU passthrough

### Shared Platform Settings

- Use `virtio` for disk and network interfaces
- Enable `discard: on` for ZFS thin provisioning
- Swap sizing guideline:
	- LXC: 1 GB
	- VM: 2 GB

## Network Requirement

- Route both qBittorrent and Prowlarr through VPN.
- Prowlarr manages indexers and qBittorrent handles downloads; in this layout both are expected to use the VPN path.
