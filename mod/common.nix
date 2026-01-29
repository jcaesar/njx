{pkgs, ...}: {
  njx.base = true;
  njx.binfmt = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.julius = import ./home/julius.nix;
  home-manager.backupFileExtension = "hm.bak";

  systemd.oomd = {
    enableUserSlices = true;
    enableSystemSlice = true;
    settings.OOM.SwapUsedLimitPercent = "90%";
  };

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
    MINISERVE_PORT = toString 1337;
  };

  environment.systemPackages = with pkgs; [
    deadnix
    # vulnix # todo
    git # better svn/hg
    nmap
    wol
  ];

  hardware.graphics.enable = true;

  users.users.julius = {
    linger = true;
    isNormalUser = true;
    extraGroups = ["wheel"];
    #openssh.authorizedKeys.keys = common.sshKeys.client;
    packages = with pkgs; [
      vim
      fish
      helix
      gh
      file
      unar
      httpie # better wget/curl, but xh is even better in most cases
      bat # better cat
      glow # cat for markdown
      socat # better netcat
      delta # better diff
      difftastic # much better diff
      oha # http bench
      sshfs
      pwgen
      binutils
      # binwalk
      bubblewrap # pretend its firejail+steamrun: bwrap --unshare-all --share-net --die-with-parent --setenv PATH /bin  --overlay-src (realpath /run/current-system/sw) --tmp-overlay /  --ro-bind /nix/store /nix/store --bind /tmp/foo /tmp --bind /run/user/1000/wayland-1 /run/user/1000/wayland-1 --ro-bind /etc /etc  --ro-bind /run/systemd/resolve /run/systemd/resolve --dev-bind /dev /dev --proc /proc /bin/nu
      urlencode
      dos2unix
      dnsutils
      tokei # better cloc
      cyrly
      qemu_kvm
      alejandra
      nixfmt
      nix-update
      nix-tree
      nix-output-monitor # better nix build
      nixpkgs-review
      cargo
      rustc
      cargo-watch
      cargo-edit
      gcc
      # python3.pkgs.python-fx # TODO fut1 vs py13
      man-pages
      expect
      (python3.withPackages (ps:
        with ps; [
          netaddr
          requests
          aiohttp
          tqdm
          matplotlib
          pandas
          numpy
        ]))
    ];
    shell = pkgs.nushell;
    password = "";
  };
}
