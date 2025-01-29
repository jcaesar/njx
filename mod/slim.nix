{...}: {
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
}
