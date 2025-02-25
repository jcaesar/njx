{
  extendModules,
  modulesPath,
  config,
  ...
}: let
  topCfg = config;
  squashzstd = "zstd -Xcompression-level 6";
  ext = modules:
    (extendModules {
      inherit modules;
    })
    .config
    .system
    .build;
  base = {
    lib,
    pkgs,
    ...
  }: {
    njx.protect-boot = false;
    boot.initrd.luks.devices = lib.mkForce {};
    fileSystems = {};
    boot.supportedFilesystems.zfs = lib.mkForce false;
    systemd.services.rescue.environment.SYSTEMD_SULOGIN_FORCE = "1";
    services.matrix-synapse.enable = lib.mkForce false; # Don't want weird stuff happening in test vms
    services.smartd.enable = false;
    boot.initrd.services.resolved.enable = false;
    security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    environment.systemPackages = [pkgs.keyutils];
  };
  common = {lib, ...}: {
    imports = [base];
    users.users.coworkerSalt = lib.mkForce {isNormalUser = true;};
    boot.initrd.systemd.enable = lib.mkForce false;
    # Should now be possible to do installs with
    # # /etc/sysflake/diskoScript
    # # nixos-install --system /etc/sysflake/toplevel
    environment.etc."sysflake/toplevel".source = topCfg.system.build.toplevel;
    environment.etc."sysflake/diskoScript" = lib.mkIf (
      topCfg.disko.devices.disk != {}
    ) {source = topCfg.system.build.diskoScript;};
  };
  installer = {
    pkgs,
    lib,
    ...
  }: {
    boot.supportedFilesystems = ["bcachefs"];
    boot.kernelPackages = lib.mkOverride 0 pkgs.linuxPackages_latest;
  };
  iso = {lib, ...}: {
    imports = [common installer];
    isoImage.squashfsCompression = squashzstd;
    programs.ssh.setXAuthLocation = lib.mkForce false; # conflict between minimal and ssh modules
  };
  sd = {
    lib,
    config,
    ...
  }: {
    imports = [common installer];
    fileSystems = lib.mkForce {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
      "/boot/firmware" = {
        device = "/dev/disk/by-label/FIRMWARE";
        fsType = "vfat";
      };
    };
    sdImage = let
      h = builtins.hashString "sha256" config.networking.hostName;
      h12 = builtins.substring 0 12 h;
    in {
      rootPartitionUUID = "00000000-0000-0000-0001-${h12}";
      compressImage = false;
    };
    environment.etc."sysflake/diskoScriptSda" = let
      cfg = topCfg.system.build;
      mov = ext [
        {
          disko.devices.disk.diks.device = lib.mkForce "/dev/sda";
        }
      ];
    in
      lib.mkIf (cfg ? diskoScript) {source = mov.diskoScript;};
  };
  vm = {
    lib,
    modulesPath,
    ...
  }: {
    imports = [
      base
      "${modulesPath}/virtualisation/qemu-vm.nix"
    ];
    boot.initrd.secrets = lib.mkForce {};
    boot.initrd.network.ssh.enable = lib.mkForce false;
    services.getty.autologinUser = "root";
    virtualisation.graphics = false;
    virtualisation.memorySize = 2048;
    systemd.services.digitalocean-metadata.enable = false;
    systemd.services.growpart.enable = false;
    systemd.network = lib.mkForce {
      enable = true;
      networks."10-test-vm-net" = {
        matchConfig.Name = "eth0";
        DHCP = "yes";
      };
    };
    networking.supplicant = lib.mkForce {};
    networking.wireless = lib.mkForce {};
    networking.wireguard.interfaces = lib.mkForce {};
    services.knot.keyFiles = [];
  };
  guivm = {lib, ...}: {
    imports = [vm];
    virtualisation.graphics = lib.mkForce true;
    services.xserver = {
      windowManager.twm.enable = true;
    };
    services.displayManager = {
      autoLogin.user = "julius";
      defaultSession = lib.mkForce "none+twm"; # TODO: Find a way to pass super from the host, then we use the host's WM
    };
  };
  netboot = {
    imports = [common "${modulesPath}/installer/netboot/netboot.nix"];
    netboot.squashfsCompression = squashzstd;
  };
in {
  # nix build --show-trace -vL .#nixosConfigurations.${host}.config.system.build.installer.isoImage
  system.build.installer = ext [iso "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"];
  system.build.installerGui = ext [iso "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"];
  # nix build --show-trace -vL .#nixosConfigurations.${host}.system.build.netboot.kexecTree
  system.build.netboot = ext [netboot];
  system.build.aarchSd = ext [sd "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"];
  system.build.aarchSdInstaller = ext [sd "${modulesPath}/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"];
  # env $"SHARED_DIR=(pwd)/share" nix run -vL .#nixosConfigurations.(hostname).system.build.test.vm
  system.build.test = ext [vm];
  system.build.testGui = ext [guivm];
}
