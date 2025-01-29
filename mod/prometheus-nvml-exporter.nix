{pkgs, ...}: {
  systemd.services."prometheus-nvml-exporter" = {
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "${pkgs.prometheus-nvml-exporter}/bin/prometheus-nvml-exporter";
      PrivateTmp = true;
      WorkingDirectory = /tmp;
      DynamicUser = true;
      User = "prometheus-nvml-exporter";
      CapabilityBoundingSet = [""];
      #DeviceAllow = ["char-nvidia* r"];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      #PrivateDevices = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };
  networking.firewall.allowedTCPPorts = [9144];
}
