{
  lib,
  config,
  ...
}: {
  options.njx.protect-boot =
    lib.mkEnableOption "umask=0077 on /boot"
    // {default = true;};
  config = lib.mkIf config.njx.protect-boot {
    fileSystems."/boot".options = ["umask=0077"];
  };
}
