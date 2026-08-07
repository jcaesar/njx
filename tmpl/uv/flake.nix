{
  inputs.pyproject-build-systems = {
    url = "github:pyproject-nix/build-system-pkgs";
    # inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {pyproject-build-systems, ...}: let
    inherit (pyproject-build-systems.inputs) nixpkgs pyproject-nix uv2nix;
  in {
    packages =
      builtins.mapAttrs (_: pkgs: {
        default = let
          python = pkgs.python3;
          pythonBase = pkgs.callPackage pyproject-nix.build.packages {inherit python;};
          util = pkgs.callPackage pyproject-nix.build.util {};
          workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};
          pythonSet = pythonBase.overrideScope (pkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.wheel
            (workspace.mkPyprojectOverlay {sourcePreference = "wheel";})
          ]);
        in
          util.mkApplication {
            venv = pythonSet.mkVirtualEnv "hello-world-env" workspace.deps.default;
            package = pythonSet.hello-world;
          };
      })
      nixpkgs.legacyPackages;
  };
}
