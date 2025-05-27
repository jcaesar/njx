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
        helix = prev.helix.overrideAttrs (old: {
          patches =
            (final.patches or [])
            ++ pkgs.lib.optional cfg.noLocalLangs ../pkgs/helix.patch;
          postInstall =
            old.postInstall or ""
            + lib.optionalString cfg.slim
            ''
              find $out/lib/runtime/grammars/ \
                -name '*.so' \
                -type f \
                ! -name nu.so \
                ! -name bash.so \
                ! -name python.so \
                ! -name nginx.so \
                ! -name yaml.so \
                ! -name json.so \
                ! -name nix.so \
                -delete
              test $(du -ks $out | grep -oE '^[0-9]*') -lt 50000
            '';
        });
      })
    ];
  };
}
