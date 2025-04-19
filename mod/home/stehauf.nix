{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) getExe;
in {
  systemd.user.services.stehauf = {
    Unit.Description = "Ich hab Rücken";
    Service.ExecStart = "${getExe pkgs.libnotify} \"Streck Dich\" \"Du krummbuckla!\"";
  };
  systemd.user.timers.stehauf = {
    Timer.OnCalendar = "*-*-* *:57 UTC";
    Install.WantedBy = ["timers.target"];
  };
}
