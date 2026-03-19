{
  pkgs,
  lib,
  config,
  ...
}: let
  private = import ../private.nix;
in {
  njx.pi3 = true;
  njx."seeed-2mic/default" = true;
  njx.sshUnlock.keys = private.terminalKeys;
  boot.initrd.systemd.enable = true;
  networking.hostName = "gegensprech";
  networking.supplicant.wlan0.extraConf = "country=JP";
  users.users.root.openssh.authorizedKeys.keys = private.terminalKeys ++ [private.prideKey];
  users.users.gegensprech = {
    isNormalUser = true;
    isSystemUser = lib.mkForce false; # so shairport can run as this user
    group = lib.mkForce "users";
    uid = 1000;
    packages = with pkgs; [gegensprech bluetui mpv-unwrapped];
    openssh.authorizedKeys.keys = private.terminalKeys;
    linger = true;
    extraGroups = ["gpio" "audio" "video"];
  };
  njx.manual.gegensprech = "Needs running `gegensprech login` as user `gegensprech`.";
  home-manager.users.gegensprech.systemd.user.services.gegensprech = {
    Unit.Description = "Gegensprech";
    Service.ExecStart = "${lib.getExe pkgs.gegensprech} run seeed-2mic";
    Service.Environment = "RUST_LOG=info,gegensprech=warn,matrix_sdk_base=warn";
    Install.WantedBy = ["default.target"];
  };
  home-manager.users.gegensprech.home.file.".config/gegensprech/cmds.yaml".text = ''
    .-: !LoopTape
        time: 90s
        send: true
        play: false
  '';
  services.shairport-sync = {
    enable = true;
    openFirewall = true;
    settings.general.name = "mamp";
    settings.general.output_backend = "pulseaudio";
    package = pkgs.shairport-sync.overrideAttrs (old: {
      configureFlags =
        old.configureFlags
        ++ [
          # todo pr
          "--with-pipewire"
          "--with-pulseaudio"
        ];
    });
    user = "gegensprech";
    arguments = "--mdns=avahi";
  };
  systemd.services.shairport-sync.environment.PULSE_SERVER = "unix:/run/user/${toString config.users.users.gegensprech.uid}/pulse/native"; # hacking around a bit much, are we?
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish.enable = true;
  };
  njx.bluetooth = true;
  security.rtkit.enable = true;
  services.pulseaudio = {
    # really wanted to use pipewire, can't get it to be a bt speaker
    # https://github.com/fdanis-oss/pw_wp_bluetooth_rpi_speaker/blob/57569e46b506782e503129f791809b2aae2b0ea6/speaker-agent.py didn't do anything
    enable = true;
    package = pkgs.pulseaudioFull;
    zeroconf.publish.enable = true;
    tcp = {
      enable = true;
      port = 4713;
      openFirewall = true;
      anonymousClients.allowAll = true;
    };
    extraConfig = ''
      set-card-profile alsa_card.usb-ESI_Audiotechnik_GmbH_UDJ6-00 output:analog-surround-51
      load-module module-remap-sink sink_name=UDJ6-56 master=alsa_output.usb-ESI_Audiotechnik_GmbH_UDJ6-00.analog-surround-51 channels=2 master_channel_map=rear-left,rear-right channel_map=front-left,front-right remix=no
      set-default-sink UDJ6-56
      load-module module-bluetooth-policy
      load-module module-bluetooth-discover
    '';
  };
  environment.systemPackages = with pkgs; [alsa-utils dtc libraspberrypi];
  systemd.user.services.wireplumber.wantedBy = ["default.target"];
  systemd.user.sockets.pipewire-pulse.wantedBy = ["default.target"]; # it's in sockets.target, yet isn't active..

  boot.initrd.systemd.services.blinky = let
    spidev = "sys-devices-platform-soc-3f204000.spi-spi_master-spi0-spi0.1-spidev-spidev0.1.device";
  in {
    unitConfig.DefaultDependencies = false;
    serviceConfig.ExecStart = "${pkgs.seeed-2mic-blinky}/bin/blinky";
    wantedBy = ["local-fs.target"];
    after = [spidev];
    requires = [spidev];
  };
  njx.extraInitrdClosures = [config.boot.initrd.systemd.services.blinky.serviceConfig];
  boot.initrd.kernelModules = ["spi_bcm2835" "spidev"];
  boot.initrd.services.udev.rules = ''
    # blinky service needs to wait with startup for spi device
    SUBSYSTEM=="spidev", ACTION!="remove", TAG+="systemd"
  '';

  system.stateVersion = "24.05";
  home-manager.users.gegensprech.home.stateVersion = "24.05";
}
