{
  lib,
  pkgs,
  nixosConfig,
  ...
}: rec {
  home.username = "julius";
  home.homeDirectory = "/home/julius";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "gruvbox";
      editor = {
        auto-pairs = false;
        auto-completion = false;
        auto-save = true;
        bufferline = "multiple";
        true-color = true;
        lsp.display-messages = true;
      };
      keys.normal = {
        "C-s" = "split_selection_on_newline";
      };
    };
    languages = {
      language = [
        {
          name = "java";
          indent = {
            tab-width = 4;
            unit = "    ";
          };
        }
        {
          name = "nix";
          language-servers = ["nixd"];
        }
      ];
      language-server.nixd.command = "${pkgs.nixd}/bin/nixd";
    };
    extraPackages = let
      p = with pkgs; [rust-analyzer rustfmt];
      pp = with pkgs.python3.pkgs; [python-lsp-server python-lsp-ruff];
    in
      p ++ pp;
  };

  # Stolen from https://wiki.nixos.org/wiki/Nushell
  programs = {
    nushell = {
      enable = true;
      package = pkgs.nushell;
      configFile.source = ../dot/config.nu;
      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
      };
    };
    starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        add_newline = true;
        scan_timeout = 5;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        aws.disabled = true;
        directory.truncate_to_repo = false;
        nix_shell.heuristic = true;
        hostname.ssh_only = false;
      };
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
  };

  programs.git = {
    enable = true;
    difftastic.enable = true;
    ignores = [".*.swp"];
    aliases = {
      l = "log --oneline --decorate --all --graph";
      lg = "log --graph --abbrev-commit --decorate --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      quickserve = "daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths .git/";
    };
    extraConfig = let
      creds = ["" "${lib.getExe pkgs.github-cli} auth git-credential"];
    in {
      pull.ff = "only";
      rerere.enable = true;
      user.name = "Julius Michaelis";
      delta.nagivate = true; # use n and N to move between diff sections
      "credential \"https://github.com\"".helper = creds;
      "credential \"https://gist.github.com\"".helper = creds;
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    desktop = "${home.homeDirectory}/.local/xdg/desktop";
    documents = "${home.homeDirectory}/docs";
    download = "${home.homeDirectory}/downloads";
    music = "${home.homeDirectory}/music";
    pictures = "${home.homeDirectory}/.local/xdg/pics";
    publicShare = "${home.homeDirectory}/.local/xdg/share";
    templates = "${home.homeDirectory}/.local/xdg/templates";
    videos = "${home.homeDirectory}/music";

    #extraConfig = ''
    #  {
    #    XDG_PROJECTS_DIR = "${home.homeDirectory}/code";
    #    XDG_GAMES_DIR = "${home.homeDirectory}/games";
    #  }
    #'';
  };

  systemd.user.services.stehauf = {
    Unit.Description = "Ich hab Rücken";
    Service.ExecStart = "${lib.getExe pkgs.libnotify} \"Streck Dich\" \"Du krummbuckla!\"";
  };
  systemd.user.timers.stehauf = {
    Timer.OnCalendar = "*-*-* *:57 UTC";
    Install.WantedBy = ["timers.target"];
  };

  services.swayidle = let
    lock = pkgs.writeShellApplication {
      name = "njx-waylock";
      runtimeInputs = [nixosConfig.programs.niri.package pkgs.swaylock pkgs.coreutils];
      text = ''
        timeout --kill-after=15 10 niri msg action power-off-monitors || true
        swaylock_args=(--show-failed-attempts)
        lock_bg="$HOME/.config/swaylock-bg"
        if test -e "$lock_bg"; then
          swaylock_args+=(--image "$lockbg")
        fi
        exec swaylock "$${swaylock_args[@]}"
      '';
    };
  in
    lib.mkIf nixosConfig.programs.niri.enable {
      enable = true;
      events = lib.singleton {
        event = "before-sleep";
        command = lib.getExe lock;
      };
      timeouts = lib.singleton {
        timeout = 310;
        command = lib.getExe lock;
      };
    };
  systemd.user.services.swww = lib.mkIf nixosConfig.programs.niri.enable {
    Service.ExecStart = lib.getExe' pkgs.swww "swww-daemon";
    Unit.PartOf = lib.singleton "graphical-session.target";
    Install.WantedBy = lib.singleton "graphical-session.target";
  };

  home.file.".config/i3/config".source = ../dot/i3/config;
  home.file.".config/niri/config.kdl".source = ../dot/niri.kdl;
  home.file.".config/waybar/config.jsonc".text = builtins.toJSON (import ../dot/waybar.nix);
  home.file.".config/alacritty/alacritty.toml".source = ../dot/alacritty.toml;
  home.file.".config/mpv/mpv.conf".source = ../dot/mpv/mpv.conf;
  home.file.".config/mpv/input.conf".source = ../dot/mpv/input.conf;
  home.file.".gdbinit".source = ../dot/gdbinit;
}
