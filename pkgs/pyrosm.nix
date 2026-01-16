{
  buildPythonPackage,
  fetchurl,
  setuptools,
  cython,
  lib,
  pytestCheckHook,
  pyrobuf,
  cykhash,
  geopandas,
  shapely,
  python-rapidjson,
}:
buildPythonPackage rec {
  pname = "pyrosm";
  version = "0.6.2";
  src = fetchurl {
    url = "mirror://pypi/${lib.substring 0 1 pname}/${pname}/${pname}-${version}.tar.gz";
    hash = "sha256-kE6WNucf1VjRJ4B6C+ubU+TS4oojAdPEbti6LYTV4bk=";
  };
  postPatch = ''
    substituteInPlace pyproject.toml --replace-fail "cykhash==" "cykhash>="
  '';
  pyproject = true;
  build-system = [setuptools];
  nativeBuildInputs = [cython];
  propagatedBuildInputs = [cykhash pyrobuf geopandas shapely python-rapidjson];
  # nativeCheckInputs = [ pytestCheckHook ];
}
