{
  pkgs,
  lib,
  ...
}: {
  users.defaultUserShell = pkgs.bashInteractive.overrideAttrs (
    lib.updateManyAttrsByPath (lib.singleton {
      path = ["env" "NIX_CFLAGS_COMPILE"];
      update = x: "${x} -DSYSLOG_HISTORY\n";
    })
  );
}
