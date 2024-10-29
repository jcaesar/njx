{
  paramiko,
  rustworkx,
  setuptools,
  pynacl,
  tqdm,
  buildPythonPackage,
}:
let
  project = (builtins.fromTOML (builtins.readFile ./pyproject.toml)).project;
in
buildPythonPackage {
  pname = project.name;
  version = project.version;
  src = ./.;
  propagatedBuildInputs = [paramiko rustworkx pynacl tqdm setuptools];
  format = "pyproject";
}
