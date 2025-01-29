let
  mainMod = "SUPER";
  yes = "yes";
in {
  # See https://wiki.hyprland.org/Configuring/Monitors/
  monitor = [
    ",preferred,auto,auto"
    #,highres,auto,auto
    #,highrr,auto,auto
    "eDP-1, 1920x1080, 0x0, 1"
  ];

  # See https://wiki.hyprland.org/Configuring/Keywords/ for more

  # Execute your favorite apps at launch
  exec-once = [
    "hyprpaper"
    "exec blueman-applet"
    "exec swayidle -w timeout 330 hyprlock before-sleep hyprlock"
    "waybar"
    "fcitx5"
  ];

  env = [
    "XCURSOR_SIZE,24"
    "NIXOS_OZONE_WL,1"
  ];

  # For all categories, see https://wiki.hyprland.org/Configuring/Variables/
  input = {
    kb_layout = "us";
    kb_variant = "altgr-intl";
    kb_model = "";
    kb_options = "compose:caps";
    kb_rules = "";

    follow_mouse = 1;

    touchpad = {
      natural_scroll = "no";
    };

    sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
  };

  general = {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more

    gaps_in = 5;
    gaps_out = 20;
    border_size = 2;
    "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
    "col.inactive_border" = "rgba(59595977)";

    layout = "dwindle";

    # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
    allow_tearing = false;
  };

  decoration = {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more

    rounding = 10;

    shadow = {
      range = 4;
      render_power = 3;
      color = "rgba(1a1a1aee)";
    };
  };

  animations = {
    enabled = yes;

    bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

    animation = [
      "windows, 1, 5, myBezier"
      "windowsOut, 1, 7, default, popin 80%"
      "border, 1, 10, default"
      "borderangle, 1, 5, default"
      "fade, 1, 5, default"
      "workspaces, 1, 3, default"
    ];
  };

  dwindle = {
    # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    pseudotile = yes; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
    preserve_split = yes; # you probably want this
  };

  master = {
    # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    # new_is_master = true;
  };

  gestures = {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    workspace_swipe = "on";
  };

  misc = {
    # See https://wiki.hyprland.org/Configuring/Variables/ for more
    force_default_wallpaper = 0; # Set to 0 to disable the anime mascot wallpapers
  };

  # Example windowrule v1
  # windowrule = float, ^(kitty)$
  # Example windowrule v2
  # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$
  # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

  bind =
    [
      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      "${mainMod}, Return, exec, alacritty"
      "${mainMod} SHIFT, Q, killactive, "
      "${mainMod} SHIFT, E, exit, "
      "${mainMod} SHIFT, Space, togglefloating,"
      "${mainMod}, W, togglegroup,"
      "${mainMod}, S, togglegroup,"
      # rofi is definitely nicer but doesn't autofocus
      #rofi -theme gruvbox-dark -combi-modi window,run,drun,ssh -show combi
      "${mainMod}, D, exec, wofi --show drun"
      "${mainMod}, B, exec, hyprlock"
      "${mainMod}, P, pseudo, # dwindle"
      "${mainMod}, E, togglesplit, # dwindle"
      "${mainMod}, F, fullscreen"
      "${mainMod}+ALT, Right, changegroupactive, f"
      "${mainMod}+ALT, Left, changegroupactive, b"

      # Move focus with mainMod + arrow keys
      "${mainMod}, left, movefocus, l"
      "${mainMod}, right, movefocus, r"
      "${mainMod}, up, movefocus, u"
      "${mainMod}, down, movefocus, d"

      # Example special workspace (scratchpad)
      "${mainMod}, S, togglespecialworkspace, magic"
      "${mainMod} SHIFT, S, movetoworkspace, special:magic"

      # Scroll through existing workspaces with mainMod + scroll
      "${mainMod}, mouse_down, workspace, e+1"
      "${mainMod}, mouse_up, workspace, e-1"

      # Brightness
      ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
      ", XF86MonBrightnessDown, exec, brightnessctl set 1%"
    ]
    ++ builtins.concatLists (builtins.genList (
        x: let
          ws = builtins.toString (x + 1 - (((x + 1) / 10) * 10));
        in [
          # Switch workspaces with mainMod + [0-9]
          "${mainMod}, ${ws}, workspace, ${toString (x + 1)}"
          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "${mainMod} SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
        ]
      )
      10);

  bindm = [
    # Move/resize windows with mainMod + LMB/RMB and dragging
    "${mainMod}, mouse:272, movewindow"
    "${mainMod}, mouse:273, resizewindow"
  ];
}
