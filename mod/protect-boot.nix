{
  lib,
  config,
  ...
}: {
  options.njx.protect-boot =
    lib.mkEnableOption "umask=0077 on /boot"
    // {default = true;};
  config = lib.mkIf config.njx.protect-boot {
    assertions = lib.singleton {
      assertion = (config.fileSystems."/boot" or {}) ? mountPoint;
      message = "No /boot, set njx.protect-boot to false";
    };
    fileSystems."/boot".options = ["umask=0077"];
  };
}
