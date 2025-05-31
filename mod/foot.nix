{...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "DejaVuSansMono:size=6.5";
        dpi-aware = "yes";
      };
      colors.alpha = 0.8;
      mouse.hide-when-typing = "yes";
    };
  };
}
