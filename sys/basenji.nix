{
  lib,
  pkgs,
  ...
}: let
  private = import ../private.nix;
in {
  networking.hostName = "basenji";

  njx.base = true;
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys;

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = true;
  boot.loader.grub.extraConfig = ''
    serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
    terminal_input serial
    terminal_output serial
  '';
  boot.loader.grub.configurationLimit = 5; # small boot
  boot.kernelParams = ["console=ttyS0,115200n8"];
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.initrd.availableKernelModules = [
    "virtiofs"
    "virtio_rng"
    "virtio_net"
    "virtio_console"
    "virtio_blk"
    "virtio_balloon"
    "virtio_pci"
    "virtio"
    "virtio_ring"
  ];
  security.acme.defaults.email = "letsencrypt-n" + "@" + "liftm.de";
  security.acme.acceptTerms = true;
  services.openssh.enable = true;
  services.qemuGuest.enable = true;
  services.airsonic = {
    enable = true;
    virtualHost = "funk.liftm.de";
    maxMemory = 2500;
  };
  services.nginx.enable = true;
  services.nginx.virtualHosts."funk.liftm.de" = {
    forceSSL = true;
    enableACME = true;
  };
  services.smartd.enable = lib.mkForce false;
  systemd.services.airsonic.path = [pkgs.ffmpeg]; # complains about not finding ffprobe
  networking.firewall.allowedTCPPorts = [80 443];
  systemd.network = {
    enable = true;
    networks."10-main" = {
      matchConfig.Name = "enp2s0";
      DHCP = "no";
      address = ["10.13.43.14/24"];
      gateway = ["10.13.43.1"];
      dns = ["10.13.43.1"];
    };
  };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    openFirewall = true;
  };

  fileSystems."/mnt/host" = {
    fsType = "virtiofs";
    device = "host";
  };
  disko.devices.disk.diks = {
    device = "/dev/vda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        mbr = {
          size = "1M";
          type = "EF02";
        };
        boot = {
          type = "EF00";
          size = "500M";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "btrfs";
            mountpoint = "/";
            mountOptions = ["defaults" "discard=async" "relatime" "compress=zstd"];
          };
        };
      };
    };
  };

  system.stateVersion = "24.11";
}
