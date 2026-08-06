pkgs:
pkgs.vector.overrideAttrs {
  cargoBuildFeatures = [
    "sinks-aws_cloudwatch_logs"
    "sources-vector"
    "sinks-vector"
    "sources-syslog"
    "sources-journald"
    "transforms-filter"
    "transforms-remap"
  ];
  cargoBuildNoDefaultFeatures = true;
}
