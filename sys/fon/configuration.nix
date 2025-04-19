{pkgs, ...}: {
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
    helix
    helix # better vim
    hostname
    htop # better top
    iftop
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
  ];

  environment.etcBackupExtension = ".bak";
  system.stateVersion = "25.05";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Asia/Tokyo";

  home-manager = {
    config = ./home.nix;
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
  };
}
