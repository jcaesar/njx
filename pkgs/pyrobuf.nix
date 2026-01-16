{
  buildPythonPackage,
  fetchurl,
  setuptools,
  cython,
  lib,
  pytestCheckHook,
  jinja2,
  distutils,
}:
buildPythonPackage rec {
  pname = "pyrobuf";
  version = "0.9.3";
  src = fetchurl {
    # no tags on github
    url = "mirror://pypi/${lib.substring 0 1 pname}/${pname}/${pname}-${version}.tar.gz";
    hash = "sha256-nMp/mSxnRkVSIkfiPPbE2BzKQuWmXkrh0F85Z7DAeoA=";
  };
  postPatch = ''
    substituteInPlace setup.py --replace-fail "'pytest-runner']" "]"
  '';
  pyproject = true;
  build-system = [setuptools];
  dependencies = [distutils];
  nativeBuildInputs = [cython];
  propagatedBuildInputs = [jinja2];
  # nativeCheckInputs = [ pytestCheckHook ];
}
