{pkgs, ...}: let
  private = import ../private.nix;
in {
  njx.pi3 = true;
  njx.dlna = true;
  njx.sshUnlock.keys = private.terminalKeys;
  njx.slim = true;
  networking.hostName = "pitivi";
  networking.supplicant.wlan0.extraConf = "country=JP";

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
    packages = with pkgs; [mpv];
    shell = pkgs.nushell;
    openssh.authorizedKeys.keys = private.terminalKeys;
  };
  environment.systemPackages = with pkgs; [libcec];

  system.stateVersion = "24.05";
}
