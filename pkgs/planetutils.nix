{
  buildPythonApplication,
  fetchFromGitHub,
  requests,
  gdal,
  curl,
  gzip,
}:
buildPythonApplication {
  pname = "planetuitls";
  version = "0.4.14";
  format = "setuptools";
  src = fetchFromGitHub {
    owner = "interline-io";
    repo = "planetutils";
    tag = "v0.4.14";
    hash = "sha256-wmiP3N86hVy0+vzHeWMn97IOdE9lzW+J6XZIuHux4KQ=";
  };
  propagatedBuildInputs = [requests gdal curl gzip];
}
