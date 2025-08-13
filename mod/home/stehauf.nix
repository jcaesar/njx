{
  pkgs,
  lib,
  nixosConfig,
  ...
}: let
  inherit (lib) getExe;
in {
  config = lib.mkIf (nixosConfig.njx.graphical or false) {
    systemd.user.services.stehauf = {
      Unit.Description = "Ich hab Rücken";
      Service.ExecStart = "${getExe pkgs.libnotify} \"Streck Dich\" \"Du krummbuckla!\"";
    };
    systemd.user.timers.stehauf = {
      Timer.OnCalendar = "*-*-* *:57 UTC";
      Install.WantedBy = ["timers.target"];
    };
  };
}
