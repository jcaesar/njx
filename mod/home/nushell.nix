{
  lib,
  pkgs,
  nixosConfig,
  config,
  ...
}: let
  cfg = config.njx.nushell;
in {
  options = {
    njx.nushell = {
      enable = lib.mkEnableOption "nushell";
      dots = lib.mkEnableOption "dots";
    };
  };
  config = {
    # Stolen from https://wiki.nixos.org/wiki/Nushell
    programs = {
      nushell = {
        enable = cfg.enable;
        package = pkgs.nushell;
        configFile.text = ''
          ${lib.optionalString cfg.dots "plugin use --plugin-config ${pkgs.nu_plugin_dots}/registry.msgpackz dots"}
          source ${../../dot/config.nu}
        '';
        shellAliases = {
          vi = "hx";
          vim = "hx";
          nano = "hx";
          peu = "pueue"; # dyslexic fingers or so
        };
        # workaround for there not being nushell support for environment.variables
        extraEnv = lib.mkIf (nixosConfig.environment or {} ? variables) ''
          mut cev = open ${pkgs.writeText "environment.variables.json" (builtins.toJSON nixosConfig.environment.variables)}
          for var in [XCURSOR_PATH XDG_CONFIG_DIRS XDG_DATA_DIRS PATH] {
            if $var in $cev and $var in $env {
              let merge = [$cev $env]
                | each { get $var | split row ":" }
                | flatten
                | uniq
                | str join ":"
              $cev = $cev | update $var $merge
            }
          }
          $cev | load-env
        '';
      };
      zoxide = {
        enable = true;
        enableNushellIntegration = true;
      };
    };
  };
}
