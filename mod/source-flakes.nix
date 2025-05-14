{
  config,
  lib,
  flakes,
  ...
}: {
  options.njx.source-flakes = lib.mkEnableOption "flake sources in /etc";
  config = lib.mkMerge [
    (
      lib.mkIf config.njx.source-flakes {
        environment.etc = let
          mkLnk = name: flake: {
            name = "sysflake/${name}";
            value.source = flake;
          };
        in
          lib.mapAttrs' mkLnk flakes;
        nix.registry.n.flake = flakes.nixpkgs;
        nix.registry.sf.flake = flakes.self;
      }
    )
    (
      lib.mkIf (!config.njx.source-flakes && flakes.nixpkgs ? rev) {
        nix.registry.n.to = {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
          rev = flakes.nixpkgs.rev;
        };
      }
    )
  ];
}
