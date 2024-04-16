{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in rec {
        devShells.default = pkgs.mkShell {
          inputsFrom = [packages.default];
          buildInputs = [pkgs.python3Packages.python-lsp-ruff];
        };
        packages.default = pkgs.python3Packages.callPackage ./. {};
      }
    );
}
