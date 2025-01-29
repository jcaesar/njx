{
  pkgs,
  config,
  lib,
  ...
}: {
  options.services.prometheus.exporters.node.njx = {
    powercap = lib.mkEnableOption "Give prometheus node exporter access to CPU wattage";
  };
  config = lib.mkIf (with config.services.prometheus.exporters.node; enable && njx.powercap) {
    systemd.services.prometheus-node-exporter.serviceConfig = {
      SupplementaryGroups = "powercap";
      ExecStartPre = ["+${pkgs.findutils}/bin/find /sys/devices/virtual/powercap -name energy_uj -exec chmod g+r -R {} + -exec chown root:powercap {} +"];
    };
    users.groups.powercap = {};
  };
}
