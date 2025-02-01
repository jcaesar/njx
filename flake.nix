{
  outputs = {
    nixpkgs,
    self,
    ...
  } @ flakes: let
    inherit (nixpkgs.lib) genAttrs attrNames attrValues mapAttrs filter;
    pkgsForSystem = system:
      import nixpkgs {
        inherit system;
        overlays = attrValues self.overlays;
      };
    genSystems = genAttrs ["x86_64-linux" "aarch64-linux"];
    eachSystem = f: genSystems (system: f (pkgsForSystem system));
    sys = system: main:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit flakes system;};
        modules = builtins.attrValues self.nixosModules ++ [main];
      };
    sysI = sys "x86_64-linux";
    sysA = sys "aarch64-linux";
  in {
    inherit flakes;
    nixosConfigurations = {
      mictop = sysI ./sys/mictop.nix;
      pekinese = sysI ./sys/pekinese/configuration.nix;
      pitivi = sysA ./sys/pitivi.nix;
      gegensprech = sysA ./sys/gegensprech.nix;
      basenji = sysI ./sys/basenji.nix;
    };
    nixosModules = {
      njx = import ./mod;
      home-manager = flakes.home-manager.nixosModules.home-manager;
      disko = flakes.disko.nixosModules.disko;
    };
    overlays.default = final: prev: import ./pkgs final prev;
    formatter = eachSystem (pkgs: pkgs.alejandra);
    checks = eachSystem (
      pkgs: let
        myPkgs = genAttrs (attrNames (self.overlays.default null null)) (p: pkgs.${p});
        sysTests = mapAttrs (_: sys: sys.config.system.build.toplevel) self.nixosConfigurations;
        aggSys = let
          all = attrNames self.nixosConfigurations;
          linkFor = sys: "ln -s ${self.nixosConfigurations.${sys}.config.system.build.toplevel} $out/${sys}";
          links = filt: builtins.concatStringsSep "\n" (map linkFor (filter (name: filt name) all));
          toplevels = filt:
            pkgs.runCommandLocal "toplevels" {} ''
              mkdir $out
              ${links filt}
            '';
        in {
          allSys = toplevels (_: true);
        };
      in
        myPkgs
        // sysTests
        // aggSys
    );
    packages = eachSystem (pkgs: {inherit (pkgs) njx;});
    apps = let
      app = program: {
        inherit program;
        type = "app";
      };
    in
      eachSystem (pkgs:
        nixpkgs.lib.genAttrs ["slack" "apply" "tag"] (n:
          app "${pkgs.njx-repo-scripts}/bin/${n}.nu")
        // nixpkgs.lib.genAttrs ["installed" "delete-generations"] (n:
          app "${pkgs.njx}/bin/njx-${n}"));
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}
