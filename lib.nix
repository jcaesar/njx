{
  self,
  nixpkgs,
}: let
  inherit (nixpkgs.lib) concatStringsSep genAttrs attrValues;
  genSystems = genAttrs ["x86_64-linux" "aarch64-linux"];
  pkgsForSystem = system:
    import nixpkgs {
      inherit system;
      overlays = attrValues self.overlays;
    };
in {
  inherit pkgsForSystem;
  eachSystem = f: genSystems (system: f (pkgsForSystem system));
  sysFs = flakes': let
    flakes = self.flakes // flakes';
    sys = system: main:
      flakes.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit flakes system;};
        modules =
          builtins.attrValues (
            flakes.njx.nixosModules
            // (flakes.self.nixosModules or {})
          )
          ++ [main];
      };
  in {
    sysI = sys "x86_64-linux";
    sysA = sys "aarch64-linux";
  };
  app = program: {
    inherit program;
    type = "app";
  };
  allToplevels = configs: pkgs: {
    allSys = let
      linkFor = sys: let em = sys.config.system; in "ln -s ${em.build.toplevel} $out/${em.name}";
    in
      pkgs.runCommandLocal "toplevels" {} ''
        mkdir $out
        ${concatStringsSep "\n" (map linkFor (attrValues configs))}
      '';
  };
}
