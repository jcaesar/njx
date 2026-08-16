{...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "DejaVuSansMono:size=6.5";
        # doesn't do anything, thus I keep a seperate version of this file for each machine/display :(
        dpi-aware = "yes";
      };
      colors-dark.alpha = 0.8;
      mouse.hide-when-typing = "yes";
      bell.urgent = "yes";
    };
  };
}
