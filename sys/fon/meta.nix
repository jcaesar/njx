{
  nix-on-droid,
  nixpkgs,
  njx,
  home-manager,
  ...
} @ flakes:
nix-on-droid.lib.nixOnDroidConfiguration {
  modules = [./configuration.nix];
  pkgs = import nixpkgs {
    system = "aarch64-linux";
    overlays = [nix-on-droid.overlays.default] ++ builtins.attrValues njx.overlays;
  };
  home-manager-path = home-manager.outPath;
  extraSpecialArgs = {inherit flakes;};
}
