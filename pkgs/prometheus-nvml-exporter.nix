{
  rustPlatform,
  fetchFromGitHub,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "prometheus-nvml-exporter";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "prometheus-nvml-exporter";
    rev = "33329c603488ed86ac3dd91939dcb77add972677";
    hash = "sha256-+UM8ZSlzJbc98jqAIidVY7bNEAmmvuYw+SrYLLGF/XM=";
  };
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };
  useFetchCargoVendor = true;

  meta = with lib; {
    description = "nvml / nvidia graphics card prometheus metrics exporter";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/${pname}";
    mainProgram = "${pname}";
  };
}
