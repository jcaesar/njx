{
  legacyclonk,
  runCommand,
  fetchurl,
  lib,
  writeShellScriptBin,
  callPackage,
  unzip,
  legacyclonkEngine ? callPackage ./engine.nix {},
  legacyclonkContent ? callPackage ./content.nix {},
  legacyclonkExtraAssets ? [legacyclonk.extraAssets.ultimate-compilation],
  legacyclonkAssetPaths ?
    lib.concatStringsSep " "
    (map (path: "${path}/*")
      (legacyclonkExtraAssets
        ++ [legacyclonkContent "${legacyclonkEngine}/{bin,share}"])),
}: let
  getAsset = key: data: let
    src = fetchurl {inherit (data) url hash;};
     name = "legacyclonk-asset-${key}-${data.version}";
    env = {
      inherit name;
      nativeBuildInputs = [unzip];
      meta = {
        license = [lib.licenses.unfreeRedistributable];
        maintainers = [lib.maintainers.jcaesar];
        inherit (data) homepage;
      };
    };
    unpack = data.script or (src: "unzip ${src} -d $out");
    cmd = ''
      mkdir $out
      ${unpack src}
    '';
  in
    runCommand name env cmd;

  # "legacy" meaning a codebase from before 1994
  # legacyclonk expects
  #  - game assets at the path where the executable is
  #  - to be able to write to the path where the executable is
  # patching around this gets pretty complicated,
  # so instead crate a directory that can be written to
  script = writeShellScriptBin "legacyclonk" ''
    set -eu

    dir="''${NIX_LEGACYCLONK_DIR:-"''${HOME:-"$(realpath ~)"}/.legacyclonk/.nix"}"
    mkdir -p "$dir"
    cd "$dir"

    for f in * Extra.c4g/*; do
      if test -L "$f"; then
        if ! test -e "$f"; then
          rm "$f"
        else
          case $(readlink "$f") in
            ${builtins.storeDir}/*)
              rm "$f"
              ;;
          esac
        fi
      fi
    done

    mkdir -p Extra.c4g
    for f in ${legacyclonkAssetPaths}; do
      if test "$(basename "$f")" == Extra.c4g; then
        for ff in "$f"/*; do
          ln -s "$ff" Extra.c4g/.
        done
      else
        ln -s "$f" .
      fi
    done
    
    # no exec, so the process stays a gc root
    ./clonk "$@"
  '';
in
  script.overrideAttrs {
    name = "legacyclonk";

    passthru = rec {
      inherit getAsset;
      engine = legacyclonkEngine;
      extraAssets = lib.mapAttrs getAsset (import ./extra.nix);
      withExtraAssets = legacyclonkExtraAssets:
        legacyclonk.override {inherit legacyclonkExtraAssets;};
    };

    meta = {
      maintainers = [lib.maintainers.jcaesar];
      homepage = "https://clonkspot.org/lc-en";
    };
  }
