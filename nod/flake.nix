{
  outputs = {
    nix-on-droid,
    njx,
    self,
  } @ flakes: {
    inherit flakes;
    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      modules = [./configuration.nix];
      pkgs = import njx.flakes.nixpkgs {
        system = "aarch64-linux";
        overlays = [nix-on-droid.overlays.default] ++ builtins.attrValues njx.overlays;
      };
      home-manager-path = njx.flakes.home-manager.outPath;
      extraSpecialArgs.flakes = flakes.njx.flakes // self.flakes;
    };
  };

  inputs = {
    njx.url = ../.;
    nix-on-droid.url = "github:nix-community/nix-on-droid/release-24.05";
    nix-on-droid.inputs.nixpkgs.follows = "njx/nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "njx/home-manager";
  };
}
