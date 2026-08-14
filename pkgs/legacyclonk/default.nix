{
  runCommand,
  fetchurl,
  lib,
  writeScriptBin,
  runtimeShell,
  callPackage,
  unzip,
  engine ? callPackage ./engine.nix {},
  extraAssets ? [],
}: let
  getAsset = name: data: let
    src = fetchurl {inherit (data) url hash;};
    env = {
      name = "legacyclonk-asset-${name}";
      nativeBuildInputs = [unzip];
      meta = {
        license = [lib.licenses.unfreeRedistributable];
        maintainers = [lib.maintainers.jcaesar];
        inherit (data) homepage;
      };
    };
    cmd = ''
      mkdir $out
      ${data.script src}
    '';
  in
    runCommand "clonk-asset-${name}" env cmd;

  assets =
    {
      main = callPackage ./content.nix {};
    }
    // lib.mapAttrs getAsset (import ./assets.nix);

  assetPaths =
    lib.concatStringsSep " "
    (map (path: "${path}/*")
      (lib.attrValues assets ++ extraAssets));

  # legacyclonk expects
  #  - game assets at the path where the executable is
  #  - to be able to write to the path where the executable is
  # patching around this gets pretty complicated,
  # so instead crate a directory that can be written to
  script = writeScriptBin "clonk" ''
    #!${runtimeShell}
    dir="''${XDG_CACHE_HOME:-"''${HOME:-"$(realpath ~)"}/.cache"}/nix-legacyclonk"
    rm -rf "$dir"
    mkdir -p "$dir"
    cd "$dir"

    mkdir Extra.c4g
    for f in ${assetPaths}; do
      if test "$(basename "$f")" == Extra.c4g; then
        for ff in "$f"/*; do
          ln -s "$ff" Extra.c4g/.
        done
      else
        ln -s "$f" .
      fi
    done
    for f in ${engine}/*; do
        ln -sf "$f" .
    done
    exec ./clonk "$@"
  '';
in
  script.overrideAttrs
  {
    name = "legacyclonk";

    passthru = {
      inherit engine assets;
    };

    meta = {
      license = [lib.licenses.cc-by-nc-40 lib.licenses.isc lib.licenses.unfreeRedistributable];
      maintainers = [lib.maintainers.jcaesar];
      homepage = "https://clonkspot.org/lc-en";
      mainProgram = "clonk";
    };
  }
