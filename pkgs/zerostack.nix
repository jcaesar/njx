{
  fetchCrate,
  rustPlatform,
}:
rustPlatform.buildRustPackage (final: {
  pname = "zerostack";
  version = "1.7.2";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-wpVCFdvYBtNNYc3t7iXgTFYPz7+lPbaFe4WeTF1uUEA=";
  };
  cargoHash = "sha256-TToiPZy9+gw/Nv//gZc92fKw2t0sGp9lEbDAWvZhceI=";
})
