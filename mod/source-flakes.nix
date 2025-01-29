{
  config,
  lib,
  flakes,
  ...
}: {
  options.njx.source-flakes = lib.mkEnableOption "flake sources in /etc";
  config = lib.mkIf config.njx.source-flakes {
    environment.etc = let
      mkLnk = name: flake: {
        name = "sysflake/${name}";
        value.source = flake;
      };
    in
      lib.mapAttrs' mkLnk flakes;
    nix.registry.n.flake = flakes.nixpkgs;
    nix.registry.sf.flake = flakes.self;
  };
}
