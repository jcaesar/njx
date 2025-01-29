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
    rev = "1e8c0f0084b9863ac8408cd942f5fd9b8c836363";
    hash = "sha256-3hXVpytETTPuzChO+v8Y4fTOHiU0k0H6XQFEdn3iYsY=";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";

  meta = with lib; {
    description = "nvml / nvidia graphics card prometheus metrics exporter";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/${pname}";
    mainProgram = "${pname}";
  };
}
