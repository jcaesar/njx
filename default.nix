{
  paramiko,
  rustworkx,
  setuptools,
  buildPythonPackage,
}:
let
  project = (builtins.fromTOML (builtins.readFile ./pyproject.toml)).project;
in
buildPythonPackage {
  pname = project.name;
  version = project.version;
  src = ./.;
  propagatedBuildInputs = [paramiko rustworkx setuptools];
  format = "pyproject";
}
