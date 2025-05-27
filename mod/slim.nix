{
  lib,
  config,
  ...
}: {
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;
  documentation.man.enable = false;
  documentation.man.man-db.enable = false;
  environment.defaultPackages = [];
  environment.stub-ld.enable = false;
  programs.less.lessopen = null;
  boot.enableContainers = false;
  programs.ssh.setXAuthLocation = false;
  services.udisks2.enable = false;
  xdg.autostart.enable = false;
  xdg.icons.enable = false;
  xdg.mime.enable = false;
  xdg.sounds.enable = false;
  # Typically too little ram for nix run nixpkgs#…
  nixpkgs.flake.setNixPath = false;
  nixpkgs.flake.setFlakeRegistry = false;
  njx.source-flakes = false;
  # make one hog pulled in from base less hoggy:
  # this will mean recompiling, and I'm currently doing emulated builds for all my arm hosts
  njx.helix.slim = lib.mkIf (config.nixpkgs.system == "x86_64-linux") true;
}
