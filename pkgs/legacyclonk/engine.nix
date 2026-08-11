{
  stdenv,
  fetchFromGitHub,
  lib,
  cmake,
  ninja,
  openssl,
  fmt,
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
  gtk2,
  pkg-config,
  libnotify,
  editor ? true, # scenario editor. run example: clonk /console Worlds.c4f/Goldmine.c4s
  headless ? false, # for dedicated server. run example: clonk /fullscreen /lobby:120 Worlds.c4f/Goldmine.c4s
}: let
  version = "359";
in
  stdenv.mkDerivation {
    pname = "legacyclonk-engine";
    inherit version;

    src = fetchFromGitHub {
      repo = "LegacyClonk";
      owner = "legacyclonk";
      rev = "refs/tags/v${version}";
      hash = "sha256-JmwJ5Yc4hSEmRFz+zkwtsw3F5wCwO3lYjpUScaz9/rs=";
    };

    nativeBuildInputs = [
      cmake
      ninja
    ];

    buildInputs =
      [
        openssl
        fmt
        libjpeg
        libpng
        zlib
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
        gtk2
        pkg-config
        libnotify
      ];

    cmakeFlags =
      [
        (lib.cmakeBool "WITH_DEVELOPER_MODE" editor)
        (lib.cmakeBool "USE_CONSOLE" headless)
      ]
      ++ lib.optionals editor [
        (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-I${gtk2}/lib/gtk-2.0/include")
      ];

    installPhase = ''
      mkdir -p $out
      install -D clonk $out/
      install -D c4group $out/
      for f in ../planet/*.c4*; do
        cp -arf "$f" $out/
      done
    '';

    meta = {
      description = "The LegacyClonk engine and the c4group command line tool.";
      license = [lib.licenses.isc];
      maintainers = [lib.maintainers.jcaesar];
      # Should work on darwin too, but probably has a different set of dependencies.
      platforms = lib.lists.intersectLists lib.platforms.linux lib.platforms.littleEndian;
      homepage = "https://clonkspot.org/lc-en";
      mainProgram = "clonk";
    };
  }
