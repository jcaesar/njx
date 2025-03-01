# workaround for https://github.com/prometheus/node_exporter/issues/3261
{
  config,
  lib,
  ...
}: let
  inherit (builtins) any attrValues;
  fs = attrValues config.fileSystems;
  mountNixStore = x: x.mountPoint == "/nix/store";
  needed = config.services.prometheus.exporters.node.enable && any mountNixStore fs;
in {
  services.prometheus.exporters.node.extraFlags =
    lib.mkIf needed
    ["--collector.filesystem.mount-points-exclude=/nix/store"];
  # can't set config.fileSystems here, infinite recursion
  systemd.mounts = lib.mkIf needed [
    {
      what = "/nix/store";
      where = "/run/.prometheus.export.nix.store";
      options = "bind";
      wantedBy = ["prometheus-node-exporter.service"];
    }
  ];
}
