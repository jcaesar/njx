{
  lib,
  config,
  pkgs,
  ...
}: {
  # workaround for there not being nushell support for environment.variables
  # can't be in home.nix because that doesn't have access to config(?), can't be in common.nix because of the key collision
  home-manager = lib.mkIf config.njx.common {
    users.julius.programs.nushell.extraEnv = ''
      mut cev = open ${pkgs.writeText "environment.variables.json" (builtins.toJSON config.environment.variables)}
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
}
