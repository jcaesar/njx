{
  outputs = {
    nixpkgs,
    self,
  }: let
    gen = f: builtins.mapAttrs f nixpkgs.legacyPackages;
  in {
    packages = gen (_: pkgs: {
      default = pkgs.python3.pkgs.callPackage ./. {};
    });
    apps = gen (system: _: nixpkgs.lib.genAttrs ["installed" "delete-generations"] (n: {
      type = "app";
      program = "${self.packages.${system}.default}/bin/njx-${n}";
    }));
  };
}
