{
  lib,
  config,
  pkgs,
  ...
}: let
  # this system doesn't actually exist, I just have this file to ensure that the modules build (which I use in some private flakes not covered by CI)
  users = ["asira" "nikita"];
  perUserTaps = 3;
in {
  njx.base = true;
  njx.binfmt = false;
  njx.logbash = true;
  njx.slim-qemu = true;
  njx.toriaezu-btrfs = true;
  njx.all-may-shutdown = true;
  njx.log-to-aws = {
    enable = true;
    group = "/real/machine";
  };
  users.users = lib.genAttrs users (u: {isNormalUser = true;});
  systemd.network = {
    enable = true;
    netdevs = (
      {
        "10-br1".netdevConfig = {
          Kind = "bridge";
          Name = "br1";
        };
      }
      // (
        let
          ifName = u: i: "${u}${toString i}";
          devConfig = u: i: {
            "10-vm-${ifName u i}" = {
              netdevConfig.Kind = "tap";
              netdevConfig.Name = "vm-${ifName u i}";
              tapConfig.User = u;
            };
          };
        in
          lib.pipe users [
            (map (u: lib.genList (devConfig u) perUserTaps))
            lib.flatten
            lib.mergeAttrsList
          ]
      )
    );
    networks."10-ens1" = {
      matchConfig.Name = "en*";
      networkConfig.Bridge = "br1";
      linkConfig.RequiredForOnline = "enslaved";
    };
    networks."10-fnet" = {
      matchConfig.Name = "br1";
      bridgeConfig = {};
      DHCP = "yes";
    };
    networks."11-vmtaps" = {
      matchConfig.Name = "vm-*";
      networkConfig.Bridge = "br1";
      linkConfig.RequiredForOnline = "enslaved";
    };
  };

  # networkd chokes on bridges in stage2 :/
  # and i don't want this to break ….test.vm
  boot.initrd.systemd.network = lib.mkForce {
    networks."10-fnet" = let
      orig =
        config.systemd.network.networks."10-fnet" or null;
    in
      if orig != null
      then
        orig
        // {
          matchConfig.Name = "en*";
        }
      else {};
    netdevs = {};
  };

  networking.nftables.enable = true;
  environment.etc.ovmf-fv.source = "${pkgs.OVMF.fd}/FV";

  system.stateVersion = config.system.nixos.release;
}
