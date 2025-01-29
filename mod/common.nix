{pkgs, ...}: {
  njx.base = true;
  njx.binfmt = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.julius = import ./home.nix;
  home-manager.sharedModules = [
    ({
      lib,
      pkgs,
      config,
      ...
    }: {
      home.activation.cleanGenerations = lib.hm.dag.entryAfter ["linkGeneration"] ''
        run ${lib.getExe' pkgs.nix "nix-env"} $VERBOSE_ARG --delete-generations \
          --profile ${config.xdg.stateHome}/nix/profiles/home-manager +1
      '';
    })
  ];
  # yay at hyprland now auto-creating its config file as long as it is running
  home-manager.backupFileExtension = "hm.bak";

  systemd.oomd = {
    enableUserSlices = true;
    enableSystemSlice = true;
    extraConfig.SwapUsedLimitPercent = "90%";
  };

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
    MINISERVE_PORT = toString 1337;
  };

  environment.systemPackages = with pkgs; [
    deadnix
    vulnix
    git # better svn/hg
  ];

  hardware.graphics.enable = true;

  users.users.julius = {
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
      bat # better cat
      glow # cat for markdown
      socat # better netcat
      delta # better diff
      difftastic # much better diff
      oha # http bench
      sshfs
      wol
      pwgen
      binutils
      binwalk
      urlencode
      nmap
      dos2unix
      dnsutils
      tokei # better cloc
      cyrly
      qemu_kvm
      alejandra
      nixfmt-rfc-style
      nix-update
      nix-tree
      nix-top
      nix-output-monitor # better nix build
      nixpkgs-review
      cargo
      rustc
      cargo-watch
      cargo-edit
      gcc
      python3.pkgs.python-fx
      rusti-cal # rustier cal
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
