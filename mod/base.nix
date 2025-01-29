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

  nixpkgs.overlays =
    lib.attrValues flakes.self.overlays
    ++ [
      (final: prev: {
        matrix-synapse-unwrapped = prev.matrix-synapse-unwrapped.overridePythonAttrs (old: {
          # #369303. tests.storage.databases.main.test_events_worker.DatabaseOutageTestCase.test_recovery fails with twisted.protocols.amp.TooLong
          postPatch =
            (old.postPatch or "")
            + ''
              substituteInPlace tests/storage/databases/main/test_events_worker.py --replace-fail \
              $'    def test_recovery(' \
              $'    from tests.unittest import skip_unless\n'\
              $'    @skip_unless(False, "broken")\n'\
              $'    def test_recovery('
              substituteInPlace tests/http/test_proxyagent.py --replace-fail \
              $'MatrixFederationAgentTests(TestCase):' \
              $'MatrixFederationAgentTests(TestCase):\n'\
              $'    skip = "Some broken"'
            '';
          # pysaml2 s broken. #367976
          nativeCheckInputs = builtins.filter (x: x.pname != "pysaml2") old.nativeCheckInputs;
        });
        # #368981
        avro-cpp = prev.avro-cpp.overrideAttrs (old: {
          cmakeFlags =
            (old.cmakeFlags or [])
            ++ [
              (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-Wno-error=dangling-reference")
            ];
        });
      })
    ];
  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.command-not-found.enable = false; # doesn't work anyway
  njx.source-flakes = lib.mkDefault true;

  boot.loader = {
    systemd-boot = {
      enable = true;
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
    httpie # better wget/curl
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
