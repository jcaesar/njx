{
  pkgs,
  config,
  ...
}: {
  njx."firefox/default" = true;
  njx.sysrq = true;

  services.logind.powerKey = "suspend";

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
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-anthy
      fcitx5-gtk
    ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
    wireplumber.enable = true;
  };
  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    glxinfo
  ];

  users.users.julius.packages = with pkgs; [
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
    gimp
    picard
    inkscape
    typst # better tex?
    xclip
    kdePackages.dolphin # better explorer.exe
    asak # "better audacity" / just an audio recorder
    gnome-clocks
    easyeffects # pipewire remixer
    omekasy # unicode font style changer
    # Hyprland stuff
    #qt6-wayland
    wofi # worse rofi
    swaylock
    swayidle
    waybar
    alacritty
    kdePackages.polkit-kde-agent-1
    brightnessctl
    grim
    wl-clipboard
  ];

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
