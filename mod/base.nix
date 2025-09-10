{
  pkgs,
  lib,
  flakes,
  config,
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
  nix.settings.keep-outputs = !config.njx.slim; # don't throw away build dependencies.
  programs.command-not-found.enable = false; # doesn't work anyway
  njx.source-flakes = lib.mkDefault true;

  home-manager.sharedModules = [./home/generation-cleanup.nix];
  system.activationScripts.nochannels = ''
    rm -rf /nix/var/nix/profiles/per-user/root/channels /root/.nix-defexpr
  '';
  system.userActivationScripts.nochannels = ''
    (
      set -u
      rm -rf "$HOME/.nix-defexpr"
    )
  '';

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
    wireguard-tools
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

  services.displayManager.gdm.autoSuspend = false;

  zramSwap = lib.mkDefault {
    enable = true;
    memoryMax = 8 * 1024 * 1024 * 1024;
    memoryPercent = 30;
  };
  systemd.services."systemd-zram-setup@" = {
    restartIfChanged = false;
    stopIfChanged = false;
  };

  programs.ssh.knownHostsFiles = [
    (pkgs.writeText "github.keys" ''
      github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
      github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
      github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    '')
  ];
}
