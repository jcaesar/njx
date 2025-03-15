{
  "position" = "bottom";
  "height" = 25;
  "spacing" = 4;
  "modules-left" = [
    "niri/workspaces"
    "niri/window"
  ];
  "modules-center" = [];
  "modules-right" = [
    "idle_inhibitor"
    "pulseaudio"
    "network"
    "cpu"
    "memory"
    "temperature"
    "backlight"
    "battery"
    "tray"
    "clock"
  ];
  "idle_inhibitor" = {
    "format" = "{icon}";
    "format-icons" = {
      "activated" = "";
      "deactivated" = "";
    };
  };
  "tray" = {
    "spacing" = 10;
  };
  "clock" = {
    "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    "format" = "{:%Y-%m-%d %H:%M}";
  };
  "cpu" = {
    "format" = "{usage}% ";
    "tooltip" = false;
  };
  "memory" = {
    "format" = "{}% ";
  };
  "temperature" = {
    "critical-threshold" = 80;
    "format" = "{temperatureC}°C {icon}";
    "format-icons" = [
      ""
      ""
      ""
    ];
  };
  "backlight" = {
    "format" = "{percent}% {icon}";
    "format-icons" = [
      ""
      ""
      ""
      ""
      ""
      ""
      ""
      ""
      ""
    ];
  };
  "battery" = {
    "states" = {
      "warning" = 30;
      "critical" = 15;
    };
    "format" = "{capacity}% {icon}";
    "format-full" = "{capacity}% {icon}";
    "format-charging" = "{capacity}% ";
    "format-plugged" = "{capacity}% ";
    "format-alt" = "{time} {icon}";
    "format-icons" = [
      ""
      ""
      ""
      ""
      ""
    ];
  };
  "network" = {
    "format-wifi" = "{essid} ({signalStrength}%) ";
    "format-ethernet" = "{ipaddr}/{cidr} ";
    "tooltip-format" = "{ifname} via {gwaddr} ";
    "format-linked" = "{ifname} (No IP) ";
    "format-disconnected" = "Disconnected ⚠";
    "format-alt" = "{ifname} = {ipaddr}/{cidr}";
  };
  "pulseaudio" = {
    "format" = "{volume}% {icon} {format_source}";
    "format-bluetooth" = "{volume}% {icon} {format_source}";
    "format-bluetooth-muted" = " {icon} {format_source}";
    "format-muted" = " {format_source}";
    "format-source" = "{volume}% ";
    "format-source-muted" = "";
    "format-icons" = {
      "headphone" = "";
      "hands-free" = "";
      "headset" = "";
      "phone" = "";
      "portable" = "";
      "car" = "";
      "default" = [
        ""
        ""
        ""
      ];
    };
    "on-click" = "pavucontrol";
  };
  "niri/workspaces" = {
    "format" = "{icon}";
    "format-icons" = {
      "browser" = "1";
      "comm" = "2";
      "program1" = "3";
      "program2" = "4";
      "foo1" = "5";
      "foo2" = "6";
      "admin" = "7";
      "foo3" = "8";
      "music" = "9";
      "media" = "0";
      "default" = "";
    };
  };
}
