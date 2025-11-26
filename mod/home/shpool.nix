{
  nixosConfig,
  lib,
  config,
  ...
}: {
  config = lib.mkMerge [
    {
      services.shpool.enable = (nixosConfig.njx.common or false) && !(nixosConfig.njx.graphical or true);
    }
    (lib.mkIf config.services.shpool.enable {
      services.shpool.settings = lib.mkIf config.programs.nushell.enable (
        lib.mkDefault {
          prompt_prefix = "";
          forward_env = ["PATH"];
        }
      );
      systemd.user.services.shpool.Install = lib.mkForce {};
    })
  ];
}
