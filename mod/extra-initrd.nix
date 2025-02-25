{
  lib,
  pkgs,
  config,
  ...
}: {
  options.njx.extraInitrdClosures = lib.mkOption {
    default = [];
  };
  config.boot.initrd.systemd.storePaths =
    lib.pipe config.njx.extraInitrdClosures
    [
      builtins.toJSON
      (pkgs.writeText "supplicant-wlan0-service-config.json")
      pkgs.writeClosure
      lib.readFile
      (lib.removeSuffix "\n")
      (lib.splitString "\n")
    ];
}
