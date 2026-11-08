{
  lib,
  fetchCrate,
  rustPlatform,
  writeShellApplication,
  sqlite,
}:
rustPlatform.buildRustPackage (final: {
  pname = "dirge-agent";
  version = "0.26.1";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-669FZRIfbc90taVr3/r4PW4B9+M6Mdg3dVrqWUsx2DY=";
  };
  cargoHash = "sha256-qJw7JTR+isfSqvX8k1mEtyYcpq0N+t00QSQ5GcXxqlc=";
  prePatch = ''
    rm -rf .cargo # forces mold
    sed -r 's/^lto = |^codegen-units =/# &/'
  '';
  nativeBuildInputs = [rustPlatform.bindgenHook];
  buildInputs = [sqlite];
  doCheck = false;
  meta.mainProgram = "dirge";
  passthru.env-ollama = writeShellApplication {
    name = "dirge-ollama-qwen";
    text = ''
      if test -z ''${DIRGE_PROVIDER+x}; then
        export DIRGE_PROVIDER=ollama
        if test -z ''${DIRGE_MODEL+x}; then
          export DIRGE_MODEL=qwen3.8
        fi
      fi
      exec ${lib.getExe final.finalPackage} "$@"
    '';
  };
})
