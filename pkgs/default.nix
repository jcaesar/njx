pkgs: prev: {
  cyrly = pkgs.callPackage ./cyrly.nix {};
  prometheus-nvml-exporter = pkgs.callPackage ./prometheus-nvml-exporter.nix {};
  gegensprech = pkgs.callPackage ./gegensprech.nix {};
  seeed-2mic-blinky = pkgs.callPackage ./seeed-2mic-blinky.nix {};
  pyanidb = pkgs.python3.pkgs.callPackage ./pyanidb.nix {};
  junix = pkgs.python3.pkgs.callPackage ./junix.nix {};
  njx = pkgs.python3.pkgs.callPackage ../tools {};
  njx-repo-scripts = pkgs.callPackage ../tools/nus.nix {};
  rowserext = pkgs.callPackage ./rowserext.nix {};
  neolink = pkgs.callPackage ./neolink.nix {};
  ruri = pkgs.callPackage ./ruri.nix {};
  colmap-vulnerable = import ./colmap.nix prev;
  windsurf = import ./windsurf.nix prev;
  vector-cloudwatchsyslogs = import ./vector-cloudwatchsyslogs.nix pkgs;
  rq = import ./rq.nix prev;
  ghcr-login = pkgs.callPackage ./ghcr-login.nix {};
  opentripplanner = pkgs.callPackage ./opentripplanner.nix {};
}
