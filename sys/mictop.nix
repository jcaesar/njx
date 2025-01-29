{pkgs, ...}: {
  nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];
  njx.common = true;
  njx.graphical = true;
  njx.dlna = true;
  njx.bluetooth = true;

  networking.hostName = "mictop";

  boot.initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  hardware.cpu.intel.updateMicrocode = true;

  boot.initrd.luks.devices."nixcrypt".device = "/dev/disk/by-uuid/09e5a891-b57f-4068-9332-5ce8c4dad926";
  boot.initrd.luks.devices."oldroot".device = "/dev/disk/by-uuid/11854422-4b07-4081-a5cf-393f4060b933";
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/74aa08e1-6c0a-42aa-8fb2-78826dc4f1e9";
    fsType = "f2fs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C7DE-A7CE";
    fsType = "vfat";
  };
  fileSystems."/mnt/oldroot" = {
    device = "/dev/disk/by-uuid/e11c57ad-ed99-45b9-82cf-b7addcf00304";
    fsType = "ext4";
  };
  fileSystems."/home/julius" = {
    device = "/mnt/oldroot/home/julius";
    fsType = "none";
    options = ["bind"];
  };

  networking.supplicant.wlp3s0.configFile.writable = true;
  networking.supplicant.wlp3s0.configFile.path = "/etc/wpa_supplicant.conf";
  networking.wireless.userControlled.enable = true;
  systemd.network = {
    enable = true;
    networks."12-wireless" = {
      matchConfig.Name = ["wlp3s0"];
      DHCP = "yes";
    };
    networks."12-wired" = {
      matchConfig.Name = ["enp0s25"];
      linkConfig.RequiredForOnline = false;
      DHCP = "yes";
    };
  };
  njx.wireguardToDoggieworld = {
    enable = true;
    listenPort = 51820;
    finalOctet = 2;
    privateKeyFile = "/etc/secret-wg-private.key";
  };

  services.xserver.enable = true;
  home-manager.users.julius.wayland.windowManager.hyprland.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  users.users.julius.packages = with pkgs; [
    element-desktop
    (himalaya.override {buildFeatures = ["notmuch"];})
    notmuch
    nextcloud-client
    wl-clipboard
    thunderbird # keine zeit für sparifankerl
    picard
  ];

  networking.extraHosts = ''
    0.0.0.0 pr0gramm.com
  '';

  powerManagement.cpufreq.max = 18000000;

  system.stateVersion = "24.05";
}
