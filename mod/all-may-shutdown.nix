{...}: {
  security.polkit = {
    enable = true;
    extraConfig = builtins.readFile ./all-may-shutdown.js;
  };
}
