{
  config,
  lib,
  pkgs,
  ...
}: let
  key = "manual";
  cfg = config.njx.${key};
  text =
    if cfg == {}
    then "No necessary manual configuration documented"
    else ''
      # Manual config

      This NixOS config isn't perfect, some things need to be done manually after install.

      ${lib.concatStringsSep "\n\n" (lib.mapAttrsToList (key: value: ''
        ## ${key}

        ${value}'')
      cfg)}
    '';
  file = pkgs.writeText "manual.md" text;
in {
  options.njx.${key} = lib.mkOption {
    default = {};
  };
  config.environment.etc."sysflake/manual".source = file;
  config.system.build.njxManual = file;
}
