{flakes, ...}: {
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
  imports = [
    "${flakes.njx}/mod/home/dot.nix"
    "${flakes.njx}/mod/home/git.nix"
    "${flakes.njx}/mod/home/helix.nix"
    "${flakes.njx}/mod/home/nushell.nix"
    "${flakes.njx}/mod/home/xdg.nix"
    "${flakes.njx}/mod/home/generation-cleanup.nix"
  ];
}
