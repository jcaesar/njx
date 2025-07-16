# remote luks unlock: $ ssh $host -p2223 -tt systemctl default
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (types) listOf str path;
  eso = mkOption {
    type = listOf str;
    default = [];
  };
  key = "sshUnlock";
  cfg = config.njx.${key};
in {
  options.njx.${key} = {
    keys = eso;
    modules = eso;
    bootDisks = mkOption {
      type = listOf path;
      default = ["/" "/boot"];
      description = "Don't fail boot even if these disks don't get unlocked quickly";
    };
  };

  config = lib.mkIf (cfg.keys != []) {
    njx.manual.boot-ssh-keys = ''
      Accessing the machine during boot via SSH requires generating the necessary SSH keys, e.g. like so:
      ```
      mkdir -p /etc/ssh/boot && chmod 700 /etc/ssh/boot && for a in rsa ed25519; do ssh-keygen -t $a -N "" -f /etc/ssh/boot/host_"$a"_key; done
      ```
      Make sure the example above is in line with the actual SSH keys that need to be generated:
      ${lib.concatStringsSep " " config.boot.initrd.network.ssh.hostKeys}
      If you generated the keys after installing, make sure to regenerate initrd, e.g. with nixos-rebuild.

      Also, if you haven't yet, confirm the necessary kernel modules with lshw ("driver=") and set them in njx.${key}.modules.
    '';

    boot.initrd = {
      kernelModules = cfg.modules;
      systemd = {
        enable = true;
        network = lib.mkDefault {
          inherit (config.systemd.network) enable config links netdevs networks;
        };
      };
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2223;
          hostKeys = [
            "/etc/ssh/boot/host_rsa_key"
            "/etc/ssh/boot/host_ed25519_key"
          ];
          authorizedKeys = cfg.keys;
        };
      };
    };
    fileSystems =
      builtins.listToAttrs
      (map
        (name: {
          inherit name;
          value = {options = ["x-systemd.device-timeout=infinity"];};
        })
        cfg.bootDisks);
  };
}
