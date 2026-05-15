# Extend partition on Nextcloud host

> After increasing the disk from Proxmox, run this on the host


- drop in a shell with necessary tooling

```sh
nix-shell -p cloud-utils
```

- run the resize ( ! choose the disk wisely)

```sh
sudo growpart /dev/sdc 1
sudo resize2fs /dev/sdc1
```

- for XFS it's different

```sh
sudo xfs_growfs /mnt/postgresql-data
```
