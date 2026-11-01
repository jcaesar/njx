{
  pkgs,
  lib,
  ...
}: {
  systemd.user.services.sleepier = let
    gsc = ["graphical-session.target"];
  in {
    path = [pkgs.systemd];
    wantedBy = gsc;
    partOf = gsc;
    after = gsc;
    requisite = gsc;
    serviceConfig.ExecStart = lib.getExe pkgs.rust-tool-garden.sleepier;
  };
}
