# Extend Partition on Nextcloud Host

Diataxis type: How-to guide

Use this procedure after increasing a disk in Proxmox and needing to grow the partition and filesystem inside the host.

## Steps

1. Open a shell with required tooling:

```sh
nix-shell -p cloud-utils
```

2. Grow partition and filesystem (example for ext4):

```sh
sudo growpart /dev/sdc 1
sudo resize2fs /dev/sdc1
```

3. If filesystem is XFS, grow the mounted filesystem instead:

```sh
sudo xfs_growfs /mnt/postgresql-data
```

## Verification

- Confirm expected size with `lsblk`.
- Confirm mounted filesystem capacity with `df -h`.
