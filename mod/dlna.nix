{...}: {
  networking.firewall = let
    rulesAllowSport = sign: ''
      iptables -${sign} nixos-fw -p udp -m udp --sport 1900 -j nixos-fw-accept
    '';
  in {
    allowedUDPPorts = [1900];
    extraCommands = rulesAllowSport "A";
    extraStopCommands = rulesAllowSport "D";
  };
}
