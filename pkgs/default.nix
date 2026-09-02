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
  vector-cloudwatchsyslogs = import ./vector-cloudwatchsyslogs.nix pkgs;
  rq = import ./rq.nix prev;
  ghcr-login = pkgs.callPackage ./ghcr-login.nix {};
  cgroup-memory-prometheus-ex = pkgs.callPackage ./cgroup-memory-prometheus-ex.nix {};
  dirge = pkgs.callPackage ./dirge.nix {};
  ferrosonic = pkgs.callPackage ./ferrosonic.nix {};
  legacyclonk = pkgs.callPackage ./legacyclonk {};
  piper-tts-small = prev.lib.pipe pkgs.piper-tts [
    (p:
      p.override {
        withTrain = false;
        withAlignment = false;
        withHTTP = false;
      })
    (p:
      p.overridePythonAttrs (old: {
        dependencies = old.dependencies ++ [(prev.lib.elemAt old.dependencies 0).pythonModule.pkgs.pyopenjtalk];
      }))
  ];
  piper-tts-voiced = pkgs.callPackage ./piper-tts-voice.nix {};
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ pkgs.lib.singleton (final: prev: {
      contextily = final.callPackage ./contextily.nix {};
      gtfs-lite = final.callPackage ./gtfs-lite.nix {};
      cykhash = final.callPackage ./cykhash.nix {};
      pyrobuf = final.callPackage ./pyrobuf.nix {};
      pyrosm = final.callPackage ./pyrosm.nix {};
    });
}
