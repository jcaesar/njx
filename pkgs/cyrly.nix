{
  rustPlatform,
  fetchFromGitHub,
  lib,
}:
rustPlatform.buildRustPackage rec {
  pname = "cyrly-conv";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "cyrly";
    rev = "b0be8833f8dab863a1afa9ab344c6be0f48fdd6a";
    hash = "sha256-Fik0Vb0WCwx1oiU/GTt703qW6OLFIWz3Fd5DC0UBU6I=";
  };
  cargoLock.lockFile = "${src}/Cargo.lock";
  buildAndTestSubdir = "bin";

  meta = with lib; {
    description = "A serde-based YAML serializer for Rust with an unusual output style.";
    license = licenses.mit;
    platforms = platforms.linux;
    homepage = "https://github.com/jcaesar/cyrly";
    mainProgram = "cyrly";
  };
}
