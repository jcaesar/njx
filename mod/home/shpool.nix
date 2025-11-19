{
  nixosConfig,
  lib,
  config,
  pkgs,
  ...
}: let
  description = "Shell Session Pooler";
  cfg = config.services.shpool;
  tomlFormat = pkgs.formats.toml {};
in {
  options.services.shpool = {
    enable = lib.mkEnableOption description;
    package = lib.mkPackageOption pkgs "shpool" {};
    settings = lib.mkOption {
      type = tomlFormat.type;
      default = {};
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/shpool/config.yml`.

        See https://github.com/shell-pool/shpool/blob/eff45bf58bd63fa60ea7f4d055b1116b4a475c1f/libshpool/src/config.rs#L180 and https://github.com/shell-pool/shpool/blob/master/CONFIG.md
      '';
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      xdg.configFile."shpool/config.toml".source = tomlFormat.generate "shpool-config.toml" cfg.settings;
      home.packages = [cfg.package];
      # https://github.com/shell-pool/shpool/tree/eff45bf58bd63fa60ea7f4d055b1116b4a475c1f/systemd
      systemd.user.services.shpool = {
        Unit = {
          Description = description;
          Requires = ["shpool.socket"];
        };
        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package} daemon";
          KillMode = "mixed";
          TimeoutStopSec = "2s";
          SendSIGHUP = "yes";
        };
        # Install.WantedBy = ["defaults.target"]; # upstream sets. but there's the socket…
      };
      systemd.user.sockets.shpool = {
        Unit.Description = description;
        Install.WantedBy = ["sockets.target"];
        Socket = {
          ListenStream = "%t/shpool/shpool.socket";
          SocketMode = "0600";
        };
      };
    })
    {
      services.shpool.settings = lib.mkIf config.programs.nushell.enable (lib.mkDefault {
        prompt_prefix = "";
        forward_env = ["PATH"];
      });
      services.shpool.enable =
        (nixosConfig.njx.common or false)
        && !(nixosConfig.njx.graphical or true);
    }
  ];
}
