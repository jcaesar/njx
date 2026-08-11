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
  njx.foot = true;
  njx.sharkwire = true;
  njx.toriaezu-btrfs = true;

  networking.hostName = "pekinese";
  system.build.sfbs-group = "1-core-2-terminal";

  boot.loader.systemd-boot.editor = lib.mkForce true;
  boot.initrd.availableKernelModules = import ./bootmods.nix;
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.initrd.systemd.enable = true;
  systemd.targets.tpm2.enable = false; # timeouts waiting on dev-tpmrm0
  hardware.cpu.intel.updateMicrocode = true;
  # system.etc.overlay.enable = true; # broken?

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
  xdg.portal.wlr.enable = true;

  users.users.julius.packages = with pkgs; [
    # element-desktop # not using it and electron is failing to compile this week
    # iamb
    # pyanidb # TODO bork
    geary
    wl-clipboard
    piper-tts-small
    vdirsyncer
    khal
    ferrosonic
    ratune
    gomuks # better element
    legacyclonk # better openclonk ;(
  ];
  njx.mail = true;

  services.avahi = {
    enable = true;
    openFirewall = true;
    publish.enable = true;
  };
  services.pipewire.extraConfig.pipewire.zeroconf-discover."context.modules" = lib.singleton {
    name = "libpipewire-module-zeroconf-discover";
    args = {};
  };

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
  # security.pam.services.lightdm.enableGnomeKeyring = true;
  programs.seahorse.enable = true;

  services.tailscale = {
    enable = true;
    port = 0; # auto?
    useRoutingFeatures = "client";
  };

  environment.systemPackages = [pkgs.iodine];

  networking.extraHosts = ''
    0.0.0.0 pr0gramm.com
  '';

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.match "^legacyclonk-asset-.*" (lib.getName pkg) != null;

  system.stateVersion = "24.05";
}
