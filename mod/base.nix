{
  pkgs,
  lib,
  flakes,
  ...
}: {
  nix.channel.enable = false;
  system.configurationRevision =
    flakes.self.rev or flakes.self.dirtyRev or "nogit";
  system.nixos.version = let
    r = flakes.self.shortRev or flakes.self.dirtyShortRev or "nogit";
  in "j_${r}_${flakes.self.lastModifiedDate}";

  nixpkgs.overlays = lib.attrValues flakes.njx.overlays;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.command-not-found.enable = false; # doesn't work anyway
  njx.source-flakes = lib.mkDefault true;

  home-manager.sharedModules = [./home/generation-cleanup.nix];

  boot.loader = {
    systemd-boot = {
      enable = lib.mkDefault true;
      configurationLimit = 15;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
  };
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";
  services.smartd.enable = lib.mkDefault true;
  services.smartd.notifications.wall.enable = true;
  networking.networkmanager.enable = false;

  environment.systemPackages = with pkgs; [
    pv
    jq
    rq
    wget
    xh # "better" httpie
    screen
    tmux # better screen
    lls # better ss -loptun
    nload
    ripgrep # better grep -R
    fd # better find
    htop # better top
    zenith-nvidia # combined htop/nload/iotop
    du-dust # better du
    iftop
    iotop
    smartmontools
    efibootmgr
    openssl
    nvd
    nix-diff
    miniserve # better python -m http.server
    inotify-tools
    tcpdump
    lshw
    cyme # better lsusb
    libtree # better ldd
    njx
    helix # better vim
    rsync # better scp
    sshfs # use it for backups. TODO script
  ];
  programs.nh.enable = true; # better nixos-rebuild
  services.openssh = {
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = lib.mkForce "prohibit-password";
    openFirewall = true;
    ports = lib.mkDefault [2222];
  };
  networking.firewall.allowedTCPPorts = [9418 1337];
  networking.useDHCP = lib.mkDefault false;

  services.xserver.displayManager.gdm.autoSuspend = false;

  zramSwap = lib.mkDefault {
    enable = true;
    memoryMax = 8 * 1024 * 1024 * 1024;
    memoryPercent = 30;
  };
}
