{
  outputs = {
    nixpkgs,
    self,
    ...
  } @ flakes': let
    flakes = flakes' // {njx = self;};
    inherit (nixpkgs.lib) genAttrs attrNames;
    inherit (self.lib) sysFs eachSystem app allToplevels;
    inherit (sysFs flakes) sysI sysA;
  in {
    inherit flakes;
    lib = import ./lib.nix {inherit self nixpkgs;};
    nixosConfigurations = {
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
    overlays.pkgs = import ./pkgs;
    overlays.fixes = import ./fixes.nix;
    formatter = eachSystem (pkgs: pkgs.alejandra);
    packages = eachSystem (pkgs: genAttrs (attrNames (self.overlays.pkgs null null)) (p: pkgs.${p}));
    apps = eachSystem (pkgs:
      genAttrs ["slack" "apply" "tag"] (n:
        app "${pkgs.njx-repo-scripts}/bin/${n}.nu")
      // genAttrs ["installed" "delete-generations"] (n:
        app "${pkgs.njx}/bin/njx-${n}"));
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    home-manager.url = "github:nix-community/home-manager";
    disko.url = "github:nix-community/disko";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
}
