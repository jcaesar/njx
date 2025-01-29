{
  setuptools,
  click,
  buildPythonPackage,
  fetchFromGitHub,
}:
buildPythonPackage {
  pname = "junix";
  version = "20220917";
  src = fetchFromGitHub {
    owner = "damienmarlier51";
    repo = "Junix";
    rev = "277abecec7357f717de407980086c80f5bff85e4";
    hash = "sha256-o+WB2v0StDbjrHdhLhLr6h3gh/uORzoYWJIvUYa7Ln0=";
  };
  propagatedBuildInputs = [setuptools click];
  doCheck = false;
  meta.description = "JUpyter Notebook Image eXporter";
}
