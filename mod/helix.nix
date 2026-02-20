{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.njx.helix;
in {
  options.njx.helix = {
    slim = lib.mkEnableOption "Patch helix to remove most grammars";
    noLocalLangs = lib.mkEnableOption "Patch helix to ignore $PROJECT_FOLDER/.helix/languages.toml";
  };
  config = {
    njx.helix.noLocalLangs = lib.mkDefault (cfg.slim || config.nixpkgs.system == "x86_64-linux");
    nixpkgs.overlays = lib.mkIf (cfg.slim || cfg.noLocalLangs) [
      (final: prev: {
        helix =
          lib.pipe prev.helix
          [
            (x:
              x.overrideAttrs (old: {
                patches =
                  (final.patches or [])
                  ++ pkgs.lib.optional cfg.noLocalLangs ../pkgs/helix.patch;
              }))
            (x:
              x.override {
                lockedGrammars =
                  lib.pipe "${lib.dirOf x.meta.position}/grammars.json"
                  [
                    lib.importJSON
                    (lib.filterAttrs (
                      k: _:
                        lib.elem k [
                          "nu"
                          "bash"
                          "python"
                          "nginx"
                          "yaml"
                          "json"
                          "nix"
                        ]
                    ))
                  ];
              })
          ];
      })
    ];
  };
}
