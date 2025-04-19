{
  home.username = "julius";
  home.homeDirectory = "/home/julius";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
  imports = [
    ./dot.nix
    ./git.nix
    ./helix.nix
    ./niri.nix
    ./nushell.nix
    ./stehauf.nix
    ./xdg.nix
  ];
}
