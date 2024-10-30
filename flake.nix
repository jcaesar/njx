{
  outputs = {nixpkgs, ...}: {
    packages =
      builtins.mapAttrs (_: pkgs: {
        default = pkgs.python3.pkgs.callPackage ./. {};
      })
      nixpkgs.legacyPackages;
  };
}
