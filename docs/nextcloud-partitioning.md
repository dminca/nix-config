# Partition disks - store data separately

> PostgreSQL and Nextcloud are stateful apps, so let's store the data on
separate disks for easing the back-up/restore process

1. **Power off the VM**
2. **In Proxmox**: Add 2 new disks (for PostgreSQL and Nextcloud data)
3. **Power on the VM**
4. **SSH into the VM and run**:

```bash
sudo nix run github:nix-community/disko -- --mode disko apply-partitions ./disk-config.nix
```
5. **Apply the NixOS config**:

```bash
sudo nixos-rebuild switch --flake .
```

The `disko apply-partitions` command will partition and format the new disks according to your disk-config.nix, then `nixos-rebuild` will mount them and initialize the PostgreSQL and Nextcloud data directories.

**Note**: Make sure you're in the flake directory when running these commands, or adjust the path to disk-config.nix accordingly.
