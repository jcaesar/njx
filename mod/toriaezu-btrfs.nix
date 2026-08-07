{...}: {
  fileSystems."/" = {
    device = "/dev/mapper/nixroot";
    fsType = "btrfs";
    options = ["discard" "compress"];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
  };
  boot.initrd.luks.devices.nixroot = {
    device = "/dev/disk/by-partlabel/primary";
    allowDiscards = true;
  };

  # TODO make a script for the installer. See bpi4 mod
  njx.manual.partitioning = ''
    ```
    disk=/dev/sda
    blkdiscard -f $disk
    parted $disk -- mklabel gpt
    parted $disk -- mkpart ESP fat32 1MB 1G
    parted $disk -- mkpart primary 1G 100%
    parted $disk -- set 1 esp on
    mkfs.fat -F 32 $disk""a
    … # rest undoc
    ```
  '';
}
