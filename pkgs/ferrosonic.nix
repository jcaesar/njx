{
  fetchCrate,
  rustPlatform,
  openssl,
  pkg-config,
}:
rustPlatform.buildRustPackage (final: {
  # apparently, this is actually ferrosonic-ng.
  # original ferrosonic is again maintained, but never squatted crates.io,
  # so all kinds of naming chaos.
  pname = "ferrosonic";
  version = "0.8.3";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-9ROrh8X12R3VQAVNUOQlSLH9THtvkhtGuIPeLSis8x8=";
  };
  cargoHash = "sha256-znpZy9i5gNYMom2jnbDr7J7slkBITTIt8rpzVMxdluM=";
  buildInputs = [openssl];
  nativeBuildInputs = [pkg-config];
})
