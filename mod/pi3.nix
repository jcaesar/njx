{
  pkgs,
  lib,
  config,
  ...
}: {
  njx.base = true;
  njx.slim = true;
  njx.sshUnlock.modules = ["smsc95xx"];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  # one little nastiness: the bootloader doesn't support secrets, so we need to hack around
  boot.initrd.secrets = lib.mkForce {};
  boot.initrd.network.ssh.hostKeys = lib.mkForce [
    "/boot/leakrets/ssh/host_rsa_key"
    "/boot/leakrets/ssh/host_ed25519_key"
  ];
  networking.supplicant.wlan0.configFile.path = "/boot/leakrets/wpa_supplicant.conf";
  boot.initrd.systemd.mounts = [
    {
      what = "/dev/mmcblk0p2";
      where = "/boot";
      type = "ext4";
    }
  ];
  # can't do: boot.initrd.networking.supplicant = config.networking.supplicant; so:
  boot.initrd.systemd.services.supplicant-wlan0 = let
    cfg = config.systemd.services.supplicant-wlan0;
  in {
    serviceConfig = cfg.serviceConfig;
    after = cfg.after ++ ["boot.mount"];
    wantedBy = ["sys-subsystem-net-devices-wlan0.device"];
    bindsTo = cfg.bindsTo;
    requires = ["boot.mount" "sys-subsystem-net-devices-wlan0.device"];
    wants = ["network.target"];
    unitConfig.DefaultDependencies = false;
  };
  # weird that it doesn't do this automatically
  njx.extraInitrdClosures = [config.systemd.services.supplicant-wlan0.serviceConfig];
  boot.initrd.systemd.groups.wheel.gid = 123;
  boot.initrd.systemd.services.sshd = {
    after = ["boot.mount"];
    requires = ["boot.mount"];
  };

  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_rpi3;
  nixpkgs.overlays = [
    (_final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // {allowMissing = true;});
    })
  ];

  boot.initrd.kernelModules = ["vc4" "bcm2835_dma" "i2c_bcm2835"];
  boot.initrd.availableKernelModules = ["brcmfmac_wcc"];
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.consoleLogLevel = lib.mkDefault 7;

  networking.supplicant.wlan0.userControlled.enable = true;
  networking.supplicant.wlan0.configFile.writable = true;
  systemd.network = {
    enable = true;
    networks."12-wireless" = {
      matchConfig.Name = ["wlan0"];
      DHCP = "yes";
    };
  };
  services.openssh.enable = true;

  disko.devices.disk.diks = {
    device = "/dev/mmcblk0";
    type = "disk";
    content = {
      type = "table";
      format = "msdos";
      partitions = [
        {
          name = "FIRMWARE";
          start = "8M";
          end = "50M";
          fs-type = "fat32";
          content = {
            type = "filesystem";
            format = "vfat";
            # still need to manually copy firmware here
            mountpoint = "/boot/firmware";
          };
        }
        {
          name = "BOOT";
          start = "50M";
          end = "1G";
          bootable = true;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/boot";
          };
        }
        {
          name = "store";
          start = "1G";
          end = "60%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/nix/store";
          };
        }
        {
          name = "luks";
          start = "60%";
          end = "100%";
          content = {
            type = "luks";
            name = "${config.networking.hostName}-crypt"; # avoid collisions when running on another raspi
            extraFormatArgs = ["--pbkdf-memory 50000"]; # eek, not enough memory with argon
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        }
      ];
    };
  };
  services.smartd.enable = false;

  users.groups.gpio = {};
  services.udev.extraRules = ''
    SUBSYSTEM=="gpiomem", KERNEL=="gpio*", GROUP="gpio",MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpio*", GROUP="gpio",MODE="0660"
    SUBSYSTEM=="spidev", KERNEL=="spidev*", GROUP="gpio",MODE="0660"
  '';

  system.stateVersion = "24.05";
}
