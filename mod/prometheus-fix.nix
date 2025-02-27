{
  config,
  lib,
  ...
}: let
  inherit (builtins) any attrValues;
  fs = attrValues config.fileSystems;
  mountNixStore = x: x.mountPoint == "/nix/store";
  needed = any mountNixStore fs;
in {
  services.prometheus.exporters.node.extraFlags =
    lib.mkIf needed ["--collector.filesystem.mount-points-exclude=/nix/store"];
}
