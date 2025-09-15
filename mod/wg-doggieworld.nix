{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  key = "wireguardToDoggieworld";
  cfg = config.njx.${key};
in {
  options.njx.${key} = {
    enable = lib.mkEnableOption "10.13.38.";
    finalOctet = lib.mkOption {
      type = with lib.types; nullOr number;
      default = null;
    };
    listenPort = lib.mkOption {
      type = with lib.types; nullOr number;
      default = null;
    };
    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/secrets/wg.pk";
    };
    v4Addr = lib.mkOption {
      type = lib.types.str;
    };
    network = lib.mkOption {
      type = options.systemd.network.networks.type.nestedTypes.elemType;
    };
    netdev = lib.mkOption {
      type = options.systemd.network.netdevs.type.nestedTypes.elemType;
    };
  };
  config = lib.mkIf cfg.enable {
    njx.manual.wg-doggieworld = ''
      Make sure /etc/secrets/wg.pk has a wireguard private key with access to doggieworld.
      E.g.:
      ```
      k=${cfg.privateKeyFile}
      wg genkey | tee $k | wg pubkey
      chown root:systemd-network $k
      chmod 640 $k
      ```
      and add that key for `${cfg.v4Addr}` on doggieworld.
    '';
    njx.${key} = {
      v4Addr = lib.mkForce "10.13.38.${toString cfg.finalOctet}";
      netdev = {
        netdevConfig =  {
          Kind = lib.mkDefault "wireguard";
          Name = lib.mkDefault "wg0";
          #MTUBytes = lib.mkDefault "1350";
        };
        wireguardConfig = {
          PrivateKeyFile = cfg.privateKeyFile;
          ListenPort = cfg.listenPort;
        };
        wireguardPeers = [
          {
            PublicKey =  "3dY3B1IlbCuBb8FrZ472u+cGXihRGE6+qmo5RZlHdFg=";
            AllowedIPs = ["10.13.38.0/24" "10.13.44.0/24" "fc00:1337:dead:beef:caff::/96"];
            Endpoint =  "128.199.185.74:13518";
            PersistentKeepalive = 29;
          }
        ];
      };
      network = {
        matchConfig.Name = "wg0";
        address = [
          "${cfg.v4Addr}/24"
          "fc00:1337:dead:beef:caff::${toString cfg.finalOctet}/96"
        ];
        DHCP = "no";
        networkConfig.IPv6AcceptRA = false;
      };
    };
    systemd.network = {
      enable = true;
      netdevs."42-wg-dev" = cfg.netdev;
      networks."42-wg-net" = cfg.network;
    };
    users.users.root.packages = [pkgs.wireguard-tools];
  };
}
