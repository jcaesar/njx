{
  outputs = {nixpkgs, ...}: let
    inherit (nixpkgs.lib) mapAttrs flip;
  in {
    packages = flip mapAttrs nixpkgs.legacyPackages (_: pkgs: {
      default = pkgs.python3.pkgs.callPackage ./. {};
    });
  };
}
