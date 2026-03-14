{
  lib,
  config,
  pkgs,
  ...
}: {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  home-manager.users.julius = lib.mkIf config.njx.common {
    systemd.user.services.mpris-proxy = {
      Unit.Description = "Mpris proxy";
      Unit.After = ["network.target" "sound.target"];
      Unit.WantedBy = ["default.target"];
      Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
  };
}
