{
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];
  njx.common = true;
  njx.graphical = true;
  njx.dlna = true;
  njx.bluetooth = true;

  networking.hostName = "pekinese";

  boot.loader.systemd-boot.editor = lib.mkForce true;
  boot.supportedFilesystems = ["bcachefs"];
  boot.initrd.availableKernelModules = import ./bootmods.nix;
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.initrd.systemd.enable = true;
  systemd.targets.tpm2.enable = false; # timeouts waiting on dev-tpmrm0
  hardware.cpu.intel.updateMicrocode = true;
  system.etc.overlay.enable = true; # i'm hoping I can speed up "activating NixOS" in stage 2 with this

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/primary";
    fsType = "bcachefs";
    options = ["compression=zstd"];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
  };
  njx.manual.partitioning = ''
    ```
    disk=/dev/sda
    blkdiscard -f $disk
    parted $disk -- mklabel gpt
    parted $disk -- mkpart ESP fat32 1MB 1G
    parted $disk -- mkpart primary 1G 100%
    parted $disk -- set 1 esp on
    mkfs.fat -F 32 $disk""a
    keyctl link @u @s # bug
    bcachefs format --encrypted --label nixroot $disk""b # Labels don't work. :(
    mount $disk""b /mnt
    mkdir /mnt/boot
    mount $disk""a /mnt/boot
    ```
  '';

  networking.supplicant.wlp0s20f3.configFile.writable = true;
  networking.supplicant.wlp0s20f3.configFile.path = "/etc/wpa_supplicant.conf";
  networking.supplicant.wlp0s20f3.userControlled.enable = true;
  systemd.network = {
    enable = true;
    networks."12-wifi-dhcp-required" = {
      matchConfig.Name = ["wlp0s20f3"];
      DHCP = "yes";
    };
    networks."12-wired-dhcp-optional" = {
      matchConfig.Name = ["enp0s31f6"];
      linkConfig.RequiredForOnline = false;
      DHCP = "yes";
    };
  };
  njx.wireguardToDoggieworld = {
    # ChUBhy0Mmeki9NKVwba0fBVWx/U6BRRwU+WKFr0jOyY=
    enable = true;
    listenPort = 35633;
    finalOctet = 13;
  };

  services.xserver.enable = true;
  programs.niri.enable = true;
  programs.waybar.enable = true;
  xdg.portal.wlr.enable = true;

  users.users.julius.packages = with pkgs; [
    element-desktop
    iamb
    pyanidb
    geary
    wl-clipboard
  ];
  njx.mail = true;

  home-manager.users.julius = {
    services.nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };

  zramSwap.memoryPercent = 200;
  nix.settings = {
    max-jobs = 2;
    cores = 1;
  };

  # necessary for nextcloud to keep its login?
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.lightdm.enableGnomeKeyring = true;
  programs.seahorse.enable = true;

  services.tailscale = {
    enable = true;
    port = 0; # auto?
  };

  networking.extraHosts = ''
    0.0.0.0 pr0gramm.com
  '';

  system.stateVersion = "24.05";
}
