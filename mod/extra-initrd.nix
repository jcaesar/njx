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
      (builtins.concatStringsSep "\n")
      (pkgs.writeText "extra-initrd-paths")
      pkgs.writeClosure
      lib.readFile
      (lib.removeSuffix "\n")
      (lib.splitString "\n")
    ];
}
