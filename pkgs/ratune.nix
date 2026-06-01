{
  fetchCrate,
  rustPlatform,
  openssl,
  pkg-config,
  alsa-lib,
}:
rustPlatform.buildRustPackage (final: {
  pname = "ratune";
  version = "0.9.9";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-jVQfvP17kmGPmaxedJ7AXAOeHi8pAbY55KP3Q/lE48s=";
  };
  cargoHash = "sha256-dIIZPAPF2SRaxS5KMPWuM7PKudw9XC5GzKtMfSvs1n8=";
  buildInputs = [openssl alsa-lib];
  nativeBuildInputs = [pkg-config];
})
