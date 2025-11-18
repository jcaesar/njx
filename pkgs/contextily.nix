{
  geopy,
  matplotlib,
  mercantile,
  pillow,
  rasterio,
  requests,
  joblib,
  xyzservices,
  fetchFromGitHub,
  buildPythonPackage,
  setuptools-scm,
}:
buildPythonPackage {
  pname = "contextily";
  version = "1.6.2";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "geopandas";
    repo = "contextily";
    rev = "refs/tags/v1.6.2";
    hash = "sha256-ucpK0YHQ95IdXbx/0Xtinuyj0UxTLx+JLN/EKoA+WOk=";
  };
  nativeBuildInputs = [setuptools-scm];
  propagatedBuildInputs = [
    geopy
    matplotlib
    mercantile
    pillow
    rasterio
    requests
    joblib
    xyzservices
  ];
}
