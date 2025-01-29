{
  rustPlatform,
  fetchFromGitLab,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "ruri";
  version = "2.1.0";

  src = fetchFromGitLab {
    owner = "timmy1e";
    repo = "ruri";
    rev = "refs/tags/v${version}";
    hash = "sha256-LbVJ8+RByFHgf0F3s6HtDF9btucffbtXUHR6oExg42o=";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";

  meta = {
    description = "Calculates the CRC-32 of files and checks them against their filename";
    license = lib.licenses.agpl3Plus;
    maintainers = [lib.maintainers.jcaesar];
    homepage = "https://gitlab.com/Timmy1e/ruri";
    mainProgram = "ruri";
  };
}
