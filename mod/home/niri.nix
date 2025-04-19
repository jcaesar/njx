{
  lib,
  pkgs,
  nixosConfig,
  config,
  ...
}: let
  inherit (lib) getExe getExe';
  lock = pkgs.writeShellApplication {
    name = "njx-waylock";
    runtimeInputs = [pkgs.swaylock];
    text = ''
      swaylock_args=(--show-failed-attempts)
      lock_bg="$HOME/.config/swaylock-bg"
      if test -e "$lock_bg"; then
        swaylock_args+=(--image "$lock_bg")
      fi
      exec swaylock "''${swaylock_args[@]}"
    '';
  };
  lockExe = getExe lock;
  windowPickExe = let
    niri = getExe pkgs.niri;
    nu = getExe pkgs.nushell;
    fuzzel = getExe pkgs.fuzzel;
  in
    pkgs.writeScript "niriswitch" ''
      #!${nu}
      # based on https://git.ersei.net/nix-configs.git/tree/home/common/wayland/niri.nix?id=a5b7a6a7d92bb6f56c6ec374499bf40acebffefc#n39
      let windows = ${niri} msg -j windows | from json
      let sel = $windows
        | format pattern $"{title}(char nul)icon(char unit_separator){app_id}"
        | str join "\n"
        | ${fuzzel} --dmenu --index
        | into int
      ${niri} msg action focus-window --id ($windows.id | get $sel)
    '';
in {
  programs.fuzzel = {
    enable = true;
    settings = {
      main.terminal = getExe pkgs.alacritty;
      main.layer = "overlay";
      colors.background = "00000077";
    };
  };

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

  services.swayidle = lib.mkIf nixosConfig.programs.niri.enable {
    enable = true;
    events = [
      {
        event = "before-sleep";
        command = lockExe;
      }
      {
        event = "lock";
        command = lockExe;
      }
    ];
    timeouts = [
      {
        timeout = 300;
        command = "${getExe nixosConfig.programs.niri.package} msg action power-off-monitors";
      }
      {
        timeout = 310;
        command = lockExe;
      }
    ];
  };
  systemd.user.services.swww = lib.mkIf nixosConfig.programs.niri.enable {
    Service.ExecStart = getExe' pkgs.swww "swww-daemon";
    Unit.PartOf = lib.singleton "graphical-session.target";
    Install.WantedBy = lib.singleton "graphical-session.target";
  };

  home.file.".config/niri/config.kdl" = lib.mkIf nixosConfig.programs.niri.enable {
    source = pkgs.substituteAll {
      src = ../../dot/niri.kdl;
      lock = lockExe;
      windowpick = windowPickExe;
      brightnessctl = getExe pkgs.brightnessctl;
      wpctl = getExe' pkgs.wireplumber "wpctl";
      fuzzel = getExe config.programs.fuzzel.package;
      alacritty = getExe pkgs.alacritty;
    };
  };
  home.file.".config/waybar/config.jsonc".text = builtins.toJSON (import ../../dot/waybar.nix);
}
