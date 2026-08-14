{
  callPackage,
  buildPackages,
  stdenv,
  fetchFromGitHub,
  lib,
  cmake,
  ninja,
  openssl,
  freetype,
  libjpeg,
  libpng,
  zlib,
  SDL2,
  SDL2_mixer,
  glew,
  libXpm,
  libXxf86vm,
  libXext,
  gtk3,
  pkg-config,
  libnotify,
  curl,
  libsysprof-capture,
  libsndfile,
  spdlog_1_14 ? callPackage ./spdlog-1.14.1.nix {},
  miniupnpc,
  editor ? true, # scenario editor. run example: clonk /console Worlds.c4f/Goldmine.c4s
  headless ? false, # for dedicated server. run example: clonk /fullscreen /lobby:120 Worlds.c4f/Goldmine.c4s
}:
stdenv.mkDerivation (final: {
  pname = "legacyclonk-engine";
  version = "364";

  src = fetchFromGitHub {
    repo = "LegacyClonk";
    owner = "legacyclonk";
    tag = "v${final.version}";
    hash = "sha256-H3IFlcBUuR+Jk6UGgU50THdE5zdtj0ctmGPqQMFbvZY=";
  };

  patches = [
    ./no-auto-update.diff
  ];

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs =
    [
      openssl
      libsysprof-capture
      libsndfile
      libjpeg
      libpng
      zlib
      curl
      spdlog_1_14
      miniupnpc
    ]
    ++ lib.optionals (!headless) [
      freetype
      SDL2
      SDL2_mixer
      glew
      libXpm
      libXxf86vm
      libXext
    ]
    ++ lib.optionals (editor && !headless) [
      gtk3
      pkg-config
      libnotify
    ];

  cmakeFlags =
    [
      (lib.cmakeBool "USE_SYSTEM_SPDLOG" true)
      (lib.cmakeBool "WITH_DEVELOPER_MODE" editor)
      (lib.cmakeBool "USE_CONSOLE" headless)
    ]
    ++ lib.optionals editor [
      # (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-I${gtk2}/lib/gtk-2.0/include")
    ];

  installPhase = let
    c4group = "${stdenv.hostPlatform.emulator buildPackages} ./c4group";
  in ''
    install -Dt $out/bin c4group clonk
    for f in ../planet/*.c4*; do
      ${c4group} "$f" -p
      install -D -t $out/share "$f"
    done
  '';

  passthru = {inherit spdlog_1_14;};

  meta = {
    description = "The LegacyClonk engine and the c4group command line tool.";
    license = [lib.licenses.isc];
    maintainers = [lib.maintainers.jcaesar lib.maintainers.lluchs]; # low level troll
    # Should work on darwin too, but probably has a different set of dependencies.
    platforms = lib.lists.intersectLists lib.platforms.linux lib.platforms.littleEndian;
    homepage = "https://clonkspot.org/lc-en";
    mainProgram = "clonk";
  };
})
