{
  outputs = {
    nixpkgs,
    self,
    nix-on-droid,
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
    nixOnDroidConfigurations.default = import ./sys/fon/meta.nix flakes;
    overlays.pkgs = import ./pkgs;
    overlays.fixes = import ./fixes.nix;
    formatter = eachSystem (pkgs: pkgs.alejandra);
    checks = eachSystem (
      pkgs: let
        myPkgs = genAttrs (attrNames (self.overlays.pkgs null null)) (p: pkgs.${p});
        aggSys = allToplevels self.nixosConfigurations pkgs;
      in
        myPkgs // aggSys
    );
    packages = eachSystem (pkgs: {inherit (pkgs) njx;});
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
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
  };
}
