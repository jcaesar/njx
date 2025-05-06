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
    rev = "94c0d5e8688ca0c208db73d32f9d46ab4139694f";
    hash = "sha256-4T58/GtaEcIGpfP+nA/VmzkINUJ+R43I2aEOLj9Kk04=";
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
