{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.njx.btspeak;
in {
  options.njx.btspeak = {
    enable = lib.mkEnableOption "BT&NW speaker via pulse";
    name = lib.mkOption {
      type = lib.types.str;
    };
    user = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    services.shairport-sync = {
      enable = true;
      openFirewall = true;
      settings.general.name = cfg.name; # todo option
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
      user = cfg.user;
      arguments = "--mdns=avahi";
    };
    systemd.services.shairport-sync.environment.PULSE_SERVER = "unix:/run/user/${toString config.users.users.${cfg.user}.uid}/pulse/native"; # hacking around a bit much, are we?
    users.users.${cfg.user} = {
      isNormalUser = true;
      isSystemUser = lib.mkForce false; # so shairport can run as this user
      group = lib.mkForce "users";
      packages = with pkgs; [pulsemixer bluetui mpv-unwrapped];
      linger = true;
      extraGroups = ["audio" "video"];
    };
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
      daemon.config = {
        # https://old.reddit.com/r/SteamPlay/comments/kw0bws/psa_if_you_have_audio_crackling/gj233tm/
        daemonize = "yes";
        high-priority = "yes";
        realtime-scheduling = "yes";
        realtime-priority = 9;
        default-fragments = 5;
        default-fragment-size-msec = 2;
      };
    };
  };
}
