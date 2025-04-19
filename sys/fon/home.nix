{
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
  imports = [
    ../../mod/home/dot.nix
    ../../mod/home/git.nix
    ../../mod/home/helix.nix
    ../../mod/home/nushell.nix
    ../../mod/home/xdg.nix
    ../../mod/home/generation-cleanup.nix
  ];
}
