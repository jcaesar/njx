{config, ...}: {
  xdg.userDirs = let
    home = config.home.homeDirectory;
  in {
    enable = true;
    createDirectories = false;
    desktop = "${home}/.local/xdg/desktop";
    documents = "${home}/docs";
    download = "${home}/downloads";
    music = "${home}/music";
    pictures = "${home}/.local/xdg/pics";
    publicShare = "${home}/.local/xdg/share";
    templates = "${home}/.local/xdg/templates";
    videos = "${home}/music";

    #extraConfig = ''
    #  {
    #    XDG_PROJECTS_DIR = "${home.homeDirectory}/code";
    #    XDG_GAMES_DIR = "${home.homeDirectory}/games";
    #  }
    #'';
  };
}
