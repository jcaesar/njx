{
  buildPythonApplication,
  fetchFromGitHub,
  boto3,
  botocore,
  urllib3,
  setuptools,
}:
buildPythonApplication {
  pname = "git-remote-s3";
  version = "0.4.2";
  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "git-remote-s3";
    rev = "v0.4.2";
    hash = "sha256-5WsDPdqhyS6LCR6226qp2xZqUsdPO9yPO5n7h4s0Z0g=";
  };
  pyproject = true;
  # nixpkgs (nixos-unstable-small) has no poetry-core, and the build
  # environment honors the upstream [build-system] requires (which uv would
  # try to install), so strip it: setuptools with the default PEP 621
  # discovery is enough for this project
  build-system = [setuptools];
  preBuild = ''
    sed -i '/^\[build-system\]/,/^$/d; /^repository = /d' pyproject.toml
  '';
  dependencies = [boto3 botocore urllib3];
  # tests require the S3-specific pytest plugins (pytest-lazy-fixture,
  # pytest-localserver) declared only as dev dependencies upstream
  doCheck = false;
}
