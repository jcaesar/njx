{
  lib,
  pkgs,
  config,
  ...
}: let
  name = "heTunnel";
  cfg = config.njx.${name};
in {
  options.njx.${name} = let
    inherit (lib) mkOption mkEnableOption;
    inherit (lib.types) string number listOf;
  in {
    enable = mkEnableOption "Hurricane Electric tunnel";
    id = mkOption {
      type = number;
      description = "Tunnel ID";
    };
    prefix = mkOption {
      type = string;
      description = "Tunnel v6 prefix";
    };
    local = mkOption {
      type = string;
      description = "Source address for tunnel";
    };
    remote = mkOption {
      type = string;
      description = "Destination address for tunnel";
      default = "74.82.46.6";
    };
    dns = mkOption {
      type = listOf string;
      description = "Add DNS server to tunnel interface";
      default = [];
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.network = {
      enable = true;
      netdevs."12-he-tunnel" = {
        netdevConfig = {
          Name = "he-ipv6";
          Kind = "sit";
          MTUBytes = toString 1480;
        };
        tunnelConfig = {
          Local = cfg.local;
          Remote = cfg.remote;
          TTL = 255;
        };
      };
      networks."he-tunnel" = {
        matchConfig.Name = "he-ipv6";
        address = ["${cfg.pfx}:2/64"];
        gateway = ["${cfg.pfx}:1"];
        dns = cfg.dns;
      };
    };
    systemd.tmpfiles.rules = [
      "D /run/he-tunnel-update 700 root root - -"
    ];
    systemd.services.he-tunnel-update = {
      serviceConfig = {
        ExecStart = lib.getExe (pkgs.writeShellApplication {
          name = "he-tunnel-update";
          runtimeInputs = with pkgs; [xh coreutils];
          text = ''xhs "https://$(cat /etc/secrets/he-tunnel-update-auth)@ipv4.tunnelbroker.net/nic/update" hostname==${toString cfg.id}'';
        });
        RootDirectory = "/run/he-tunnel-update";
        BindReadOnlyPaths = [
          "/nix/store"
          "/etc/secrets/he-tunnel-update-auth"
          "/etc/resolv.conf"
        ];
      };
    };
    systemd.timers.he-tunnel-update = {
      timerConfig = {
        OnCalendar = "09:01:33 Asia/Tokyo"; # random
        OnBootSec = "300s";
      };
      wantedBy = ["timers.target"];
    };
    njx.manual.he-tunnel = ''
      Place $user:$pass file in /etc/secrets/he-tunnel-update-auth.
      See https://ipv4.tunnelbroker.net/tunnel_detail.php?tid=${toString cfg.id}
    '';
  };
}
