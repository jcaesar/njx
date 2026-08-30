{
  pkgs,
  config,
  ...
}: let
  pkgsCross = config.system.build.argsCross.x86_64-linux.pkgs;
  private = import ../private.nix;
in {
  njx.pi3 = true;
  njx.dlna = true;
  njx.sshUnlock.keys = private.terminalKeys;
  njx.slim = true;
  networking.hostName = "pitivi";
  system.build.sfbs-group = "3-other-2-raspis";
  networking.supplicant.wlan0.extraConf = "country=JP";
  njx.btspeak = {
    enable = true;
    name = "mamp";
    user = "media";
  };

  systemd.network = {
    enable = true;
    networks."12-wired" = {
      matchConfig.Name = ["enu1u1"];
      linkConfig.RequiredForOnline = false;
      DHCP = "yes";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys ++ [private.prideKey];
  users.users.media = {
    isNormalUser = true;
    packages = with pkgs; [mpv pkgsCross.ferrosonic];
    shell = pkgs.nushell;
    openssh.authorizedKeys.keys = private.terminalKeys;
    uid = 1000;
  };
  home-manager.users.media.home = {
    file.".config/mpv/input.conf".source = ../dot/mpv/input.conf;
    file.".config/mpv/mpv.conf".text = ''
      volume=80
      audio-display=no
      save-position-on-quit=yes
      no-video=yes
      gapless-audio=yes
      cache=yes
      cache-secs=10
    '';
    stateVersion = "26.05";
  };
  environment.systemPackages = with pkgs; [libcec];

  system.stateVersion = "24.05";
}
