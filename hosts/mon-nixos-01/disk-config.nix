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
            device = lib.mkDefault "/dev/disk/by-partlabel/disk-disk1-boot";
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            device = lib.mkDefault "/dev/disk/by-partlabel/disk-disk1-ESP";
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
            device = lib.mkDefault "/dev/disk/by-partlabel/disk-disk1-root";
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
          prometheus = {
            device = lib.mkDefault "/dev/disk/by-partlabel/disk-disk2-prometheus";
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/prometheus-data";
            };
          };
        };
      };
    };
    disk.disk3 = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi2";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          grafana = {
            device = lib.mkDefault "/dev/disk/by-partlabel/disk-disk3-grafana";
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/grafana-data";
            };
          };
        };
      };
    };
    disk.disk4 = {
      device = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi3";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          loki = {
            device = lib.mkDefault "/dev/disk/by-partlabel/disk-disk4-loki";
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/mnt/loki-data";
            };
          };
        };
      };
    };
  };
}
