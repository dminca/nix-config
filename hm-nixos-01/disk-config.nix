{ lib, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            device = "/dev/disk/by-partlabel/disk-disk1-boot";
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            device = "/dev/disk/by-partlabel/disk-disk1-ESP";
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            device = "/dev/disk/by-partlabel/disk-disk1-root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
    disk.disk2 = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          postgresql = {
            device = "/dev/disk/by-partlabel/disk-disk2-postgresql";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/appdata";
            };
          };
        };
      };
    };
  };
}
