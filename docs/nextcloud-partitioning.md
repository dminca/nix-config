# Partition Disks for Nextcloud and PostgreSQL Data

Diataxis type: How-to guide

Use this guide to move stateful Nextcloud and PostgreSQL data to separate disks for easier backup and restore workflows.

## Steps

1. Power off the VM.
2. In Proxmox, attach two new disks:
	- one for PostgreSQL
	- one for Nextcloud data
3. Power on the VM.
4. SSH into the VM and apply partition layout:

```bash
sudo nix run github:nix-community/disko -- --mode disko apply-partitions ./disk-config.nix
```

5. Apply NixOS configuration:

```bash
sudo nixos-rebuild switch --flake .
```

## Result

- New disks are partitioned and formatted per `disk-config.nix`.
- Mounts and service paths are activated during rebuild.

## Notes

- Run commands from the flake directory, or provide full path to `disk-config.nix`.
- Validate mounts after rebuild with `lsblk` and `findmnt`.
