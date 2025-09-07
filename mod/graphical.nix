{
  pkgs,
  config,
  lib,
  ...
}: {
  njx."firefox/default" = true;
  njx.sysrq = true;
  njx.nix-lowprio = true;

  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandleLidSwitch = "ignore";
  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  fonts.packages = with pkgs; [
    ipafont
    ipaexfont
    hanazono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    nerd-fonts.droid-sans-mono
    fira-code
    terminus_font
    iosevka
    sarasa-gothic
    source-code-pro
    terminus_font
    inconsolata
  ];

  services.xserver = {
    xkb = {
      layout = "us";
      options = "compose:caps";
      variant = "altgr-intl";
    };
    extraConfig = ''
      Section "ServerFlags"
        Option "MaxClients" "2048"
      EndSection
    '';
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-anthy
      fcitx5-gtk
    ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
    wireplumber.enable = true;
  };
  services.pulseaudio.enable = lib.mkDefault false;

  environment.systemPackages = with pkgs; [
    glxinfo
  ];

  users.users.julius.packages = with pkgs;
    [
      xpra
      mpv
      yt-dlp
      vlc # better windows media player
      helvum # pipewire patch bay
      pulseaudio
      pavucontrol
      dunst # better du
      gomuks # better element
      activitywatch
      sxiv # better feh
      imv # because sxiv doesn't do wayland
      zathura
      imagemagick
      libreoffice-still
      rusti-cal # rustier cal
      gimp3
      picard
      inkscape
      typst # better tex?
      xclip
      kdePackages.dolphin # better explorer.exe
      asak # "better audacity" / just an audio recorder
      gnome-clocks
      easyeffects # pipewire remixer
      omekasy # unicode font style changer
      alacritty
      #qt6-wayland
      wl-clipboard
      waypipe
    ]
    ++ lib.optionals config.programs.niri.enable [
      wofi # worse rofi
      swaylock
      swayidle
      kdePackages.polkit-kde-agent-1
      brightnessctl
      swww
      xwayland-satellite
      ffmpeg
    ];
  programs.waybar.enable = lib.mkIf config.programs.niri.enable true;
  programs.waybar.package = pkgs.waybar.override {
    gpsSupport = false;
    jackSupport = false;
    mpdSupport = config.services.mpd.enable;
    sndioSupport = false;
    upowerSupport = config.services.upower.enable;
    wireplumberSupport = config.services.pipewire.enable;
    pulseSupport = config.services.pulseaudio.enable || config.services.pipewire.enable;
    cavaSupport = false;
  };

  system.systemBuilderCommands = let
    # reproduce nonexposed envs from nixos/modules/hardware/opengl.nix
    cfg = config.hardware.graphics;
    package = pkgs.buildEnv {
      name = "opengl-drivers";
      paths = [cfg.package] ++ cfg.extraPackages;
    };
  in ''
    mkdir -p $out/opengl
    ln -s ${package} $out/opengl/driver
  '';
  systemd.tmpfiles.rules = [
    "L+ /run/opengl-driver - - - - /run/booted-system/opengl/driver"
  ];
}
