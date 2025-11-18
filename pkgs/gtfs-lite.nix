{
  buildPythonPackage,
  fetchFromGitHub,
  pandas,
}:
buildPythonPackage {
  pname = "gtfs-lite";
  version = "0.2.1";
  src = fetchFromGitHub {
    owner = "wklumpen";
    repo = "gtfs-lite";
    tag = "v0.2.1";
    # rev = "430c0216aef07d3c1a8efcc493caeb7e407a356e";
    hash = "sha256-OK7jxzpt+fg407g33aAx3qM6RWXbUm8MjALN2SWcV0Y=";
  };
  format = "setuptools";
  propagatedBuildInputs = [pandas];
  pythonImportsCheck = ["gtfslite"];
}
