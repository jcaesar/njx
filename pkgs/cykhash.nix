{
  buildPythonPackage,
  setuptools,
  fetchurl,
  cython,
  lib,
}:
buildPythonPackage rec {
  pname = "cykhash";
  version = "2.0.1";
  pyproject = true;
  build-system = [setuptools];
  src = fetchurl {
    # 2.0.1 is not tagged on github
    url = "mirror://pypi/${lib.substring 0 1 pname}/${pname}/${pname}-${version}.tar.gz";
    hash = "sha256-tHlLyfVJEU2M8dhW2fZOCP9fJGvwQ882n9tBTpzrl/c=";
  };
  nativeBuildInputs = [cython];
}
