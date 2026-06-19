{
  fetchFromGitHub,
  rustPlatform,
  python3,
  perl,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage (final: {
  pname = "maki";
  version = "0.3.18";
  src = fetchFromGitHub {
    owner = "tontinton";
    repo = final.pname;
    tag = "v${final.version}";
    hash = "sha256-YZbdAkPFrCEZ1vPLnhjFgIM5wU0FTa3+LUcBz4mTswc=";
  };
  cargoHash = "sha256-uXCnFmXLQw7vKyJ7Z4TQuUeA3tfJH89fljVfru4d1CY=";
  cargoBuildFlags = ["--package" final.pname];
  nativeBuildInputs = [
    python3
    perl
    pkg-config
  ];
  buildInputs = [openssl];
  postPatch = ''
    substituteInPlace "$cargoDepsCopy"/*/monty-*/src/lib.rs \
      --replace-fail \
      '#![doc = include_str!("../../../README.md")]' \
      '#![doc = "MPB"]'
  '';
})
