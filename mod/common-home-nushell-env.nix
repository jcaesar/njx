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
      open ${pkgs.writeText "environment.variables.json" (builtins.toJSON config.environment.variables)} | load-env
    '';
  };
}
