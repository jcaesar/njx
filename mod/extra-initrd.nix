{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.njx.extraInitrdClosures;
  set = lib.pipe cfg [
    builtins.toJSON
    (pkgs.writeText "supplicant-wlan0-service-config.json")
    pkgs.writeClosure
    lib.readFile
    (lib.removeSuffix "\n")
    (lib.splitString "\n")
  ];
in {
  options.njx.extraInitrdClosures = lib.mkOption {
    default = [];
  };
  config.boot.initrd.systemd.storePaths = lib.mkIf (cfg != []) set;
}
