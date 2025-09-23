{
  rustPlatform,
  fetchFromGitHub,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "cgroup-memory-prometheus-ex";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = pname;
    rev = "07667fbd8689eccea14699e49e3df0da5e2c04c0";
    hash = "sha256-e05QKX86CsW+b5xqJw1bEllcr7OtKliZEGBF5Oi2h3E=";
  };
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  meta = with lib; {
    description = "Exports a single vector of metrics for the exclusive memory use per cgroup";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/${pname}";
    mainProgram = "cgroup-mem-exporter";
  };
}
