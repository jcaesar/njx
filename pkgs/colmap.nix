pkgs: ((pkgs.colmap.override {
    freeimage = pkgs.freeimage.overrideAttrs {
      # Seriously, only use on trusted input
      meta = pkgs.freeimage.meta // {knownVulnerabilities = [];};
    };
  })
  .overrideAttrs (prev: {
    cmakeFlags = ["-DUSE_CUDA=ON" "-DCMAKE_CUDA_ARCHITECTURES=75"];
    nativeBuildInputs = prev.nativeBuildInputs ++ [pkgs.qt5.wrapQtAppsHook];
    buildInputs =
      prev.buildInputs
      ++ [
        pkgs.flann
        pkgs.cgal
        pkgs.gmp
        pkgs.mpfr
        pkgs.xorg.libSM
      ];
    src = pkgs.fetchFromGitHub {
      owner = "colmap";
      repo = "colmap";
      rev = "3.9.1";
      hash = "sha256-Xb4JOttCMERwPYs5DyGKHw+f9Wik1/rdJQKbgVuygH8=";
    };
  }))
