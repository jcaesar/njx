{
  fetchCrate,
  rustPlatform,
}:
rustPlatform.buildRustPackage (final: {
  pname = "dirge-agent";
  version = "0.21.11";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-2otfcbv1rn4zX0/FlW3hTxqBGaMvS3R5hxLiE/itCjc=";
  };
  cargoHash = "sha256-1YIrOkjqI44GkSf0002qAvltBprg1DoTcXjYiw/jJyE=";
  prePatch = "rm -rf .cargo # forces mold";
  nativeBuildInputs = [rustPlatform.bindgenHook];
  doCheck = false;
})
