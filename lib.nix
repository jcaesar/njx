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
  eachSystem = f: genSystems (system: f (pkgsForSystem system));
  app = program: {
    inherit program;
    type = "app";
  };
in {
  inherit pkgsForSystem eachSystem;
  sysFs = flakes': let
    flakes = self.flakes // flakes';
    sys = system: main:
      flakes.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit flakes system;};
        modules = builtins.attrValues flakes.njx.nixosModules ++ [main];
      };
  in {
    sysI = sys "x86_64-linux";
    sysA = sys "aarch64-linux";
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
  apps = eachSystem (pkgs:
    genAttrs ["slack" "tag"] (n:
      app "${pkgs.njx-repo-scripts}/bin/${n}.nu")
    // genAttrs ["installed" "delete-generations"] (n:
      app "${pkgs.njx}/bin/njx-${n}")
    // {apply = app (pkgs.njx-repo-scripts.apply self);});
}
