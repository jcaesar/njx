pkgs:
pkgs.vector.overrideAttrs {
  cargoBuildFeatures = [
    "unix"
    "sinks-aws_cloudwatch_logs"
    "sources-syslog"
    "sources-journald"
    "transforms-filter"
    "transforms-remap"
  ];
  cargoBuildNoDefaultFeatures = true;
}
