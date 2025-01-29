pkgs: prev: {
  cyrly = pkgs.callPackage ./cyrly.nix {};
  prometheus-nvml-exporter = pkgs.callPackage ./prometheus-nvml-exporter.nix {};
  gegensprech = pkgs.callPackage ./gegensprech.nix {};
  seeed-2mic-blinky = pkgs.callPackage ./seeed-2mic-blinky.nix {};
  pyanidb = pkgs.python3.pkgs.callPackage ./pyanidb.nix {};
  junix = pkgs.python3.pkgs.callPackage ./junix.nix {};
  njx = pkgs.callPackage ./njx.nix {};
  rowserext = pkgs.callPackage ./rowserext.nix {};
  ruri = pkgs.callPackage ./ruri.nix {};
  colmap = import ./colmap.nix prev;
  vector-cloudwatchsyslogs = import ./vector-cloudwatchsyslogs.nix pkgs;
}
