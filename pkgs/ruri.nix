{
  rustPlatform,
  fetchFromGitLab,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "ruri";
  version = "2.1.1";

  src = fetchFromGitLab {
    owner = "timmy1e";
    repo = "ruri";
    tag = "v${version}";
    hash = "sha256-321kpkOCYHqAQo8KKiiGc+Dz2NApLTyylddrCNGj62I=";
  };
  cargoHash = "sha256-sC0vR6uHWlXEc+XWAoH4nF6AwQbfki/dB2X69k6Kpy4=";

  meta = {
    description = "Calculates the CRC-32 of files and checks them against their filename";
    license = lib.licenses.agpl3Plus;
    maintainers = [lib.maintainers.jcaesar];
    homepage = "https://gitlab.com/Timmy1e/ruri";
    mainProgram = "ruri";
  };
}
