{
  lib,
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
  version = "1.7.0";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "geopandas";
    repo = "contextily";
    tag = "v1.7.0";
    hash = "sha256-qAc4WM64b026kuwARLAXgJFXMU8I2O4nXh5aDxzThtI=";
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

  meta = {
    description = "Context geo-tiles in Python";
    license = lib.licenses.bsd3;
    maintainers = [lib.maintainers.jcaesar];
    homepage = "https://github.com/geopandas/contextily/";
  };
}
