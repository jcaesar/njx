{config, ...}: {
  # -j nixos-fw-log-refuse is more fragile than one might think:
  # The default nixos setup first deletes chains with -X || true,
  # then recreates them with -N (no … || true).
  # If a chain like nixos-fw-refuse still has references,
  # the deletion will fail, and then the entire script will fail at re-creation.
  networking.firewall.extraCommands = ''
    # njx: Don't accidentally be a router
    ip46tables -P FORWARD DROP
    ip46tables -A FORWARD -j nixos-fw-log-refuse
  '';
  networking.firewall.extraStopCommands = ''
    ip46tables -D FORWARD -j nixos-fw-log-refuse
  '';
  assertions = [
    {
      assertion = !config.virtualisation.docker.enable;
      message = "docker bug? external connectivity breaks when this is enabled and a network is created";
    }
  ];
}
