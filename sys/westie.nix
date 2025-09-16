{
  networking.hostName = "westie";
  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "sr_mod"];
  boot.initrd.systemd.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  njx.base = true;
  services.sshd.enable = true;
  users.users.root.openssh.authorizedKeys.keys = (import ../private.nix).terminalKeys;
  njx.sshUnlock.keys = (import ../private.nix).terminalKeys;
  njx.sshUnlock.modules = ["tg3" "e1000e" "bridge"];
  fileSystems."/" = {
    fsType = "btrfs";
    device = "/dev/mapper/nixroot";
    options = ["discard" "compress"];
  };
  fileSystems."/boot" = {
    fsType = "vfat";
    device = "/dev/disk/by-partlabel/nixboot";
  };
  fileSystems."/mnt/data" = {
    fsType = "btrfs";
    device = "/dev/mapper/data";
  };
  boot.initrd.luks.devices.nixroot = {
    device = "/dev/disk/by-label/nixcrypt";
    allowDiscards = true;
  };
  boot.initrd.luks.devices.data = {
    device = "/dev/disk/by-label/data";
  };
  njx.manual.disks = ''
    ```
    sgdisk --clear --align-end --new=1:0:+1G --typecode=1:EF00 --change-name=1:nixboot --new=2:0:-0 --typecode=2:8300 /dev/nvme0n1
    cryptsetup luksFormat /dev/nvme0n1p2 --label nixcrypt
    cryptsetup luksOpen /dev/disk/by-label/nixcrypt nixroot
    mkfs.btrfs /dev/mapper/nixroot
    mount /dev/mapper/nixroot /mnt -odiscard,compress=zstd
    mkfs.fat -F32 /dev/disk/by-partlabel/nixboot
    mkdir /mnt/boot
    mount /dev/disk/by-partlabel/nixboot /mnt/boot/
    cryptsetup luksFormat /dev/disk/by-id/ata-TOSHIBA_MG10AFA22TE_X4B0A028FM8J --label data
    ```
    - The label on the ata-TOSHIBA LUKS didn't stick
    - May need manual bootctl install after nixos-install.
  '';
  systemd.network = {
    enable = true;
    netdevs.br.netdevConfig = {
      Kind = "bridge";
      Name = "br";
    };
    networks.br = {
      matchConfig.Name = "br";
      DHCP = "yes";
    };
    networks.phy = {
      matchConfig.Name = "enp*";
      networkConfig.Bridge = "br";
    };
  };
  system.stateVersion = "25.11";
}
