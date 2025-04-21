{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../mod/source-flakes.nix
  ];
  njx.source-flakes = true;

  environment.packages = with pkgs; [
    bat # better cat
    binutils
    bzip2
    difftastic # much better diff
    diffutils
    dnsutils
    dos2unix
    du-dust # better du
    fd # better find
    file
    findutils
    glow # cat for markdown
    gnugrep
    gnupg
    gnused
    gnutar
    gzip
    hostname
    htop # better top
    iftop
    imagemagick
    iotop
    jq
    killall
    man
    man-pages
    miniserve # better python -m http.server
    nix-output-monitor # better nix build
    njx
    nload
    nmap
    oha # http bench
    openssl
    procps
    pv
    pwgen
    ripgrep # better grep -R
    rq
    rsync # better scp
    screen
    socat # better netcat
    sshfs
    sshfs # use it for backups. TODO script
    tmux # better screen
    tokei # better cloc
    tzdata
    unar
    unzip
    urlencode
    utillinux
    vim
    wget
    wol
    xh # "better" httpie
    xz
    zip
    (writeShellScriptBin "ping" ''
      /android/system/bin/linker64 /android/system/bin/ping "$@"
    '')
  ];

  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-setup-storage.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    xdg-open.enable = true;
  };

  environment.etcBackupExtension = ".bak";
  system.stateVersion = "24.05";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Asia/Tokyo";

  user.shell = lib.getExe config.home-manager.config.programs.nushell.package;
  home-manager = {
    config = ./home.nix;
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
  };
}
