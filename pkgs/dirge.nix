{
  fetchCrate,
  rustPlatform,
}:
rustPlatform.buildRustPackage (final: {
  pname = "dirge-agent";
  version = "0.24.0";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-5SaHLDYBblOog3Bd2JqcpA1zZz82M7kmHawxD/9X+3k=";
  };
  cargoHash = "sha256-RTVDwien6QsCMdTgwkiEpP0wkHt1PJdwpxv84YCpuck=";
  prePatch = "rm -rf .cargo # forces mold";
  nativeBuildInputs = [rustPlatform.bindgenHook];
  doCheck = false;
  meta.mainProgram = "dirge";
})
