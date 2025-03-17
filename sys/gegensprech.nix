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
    packages = with pkgs; [gegensprech];
    openssh.authorizedKeys.keys = private.terminalKeys;
    linger = true;
    extraGroups = ["gpio"];
  };
  home-manager.users.gegensprech.systemd.user.services.gegensprech = {
    Unit.Description = "Gegensprech";
    Service.ExecStart = "${lib.getExe pkgs.gegensprech} run seeed-2mic";
    Service.Environment = "RUST_LOG=info,gegensprech=warn";
    Install.WantedBy = ["default.target"];
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  environment.systemPackages = with pkgs; [alsa-utils dtc libraspberrypi];

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
