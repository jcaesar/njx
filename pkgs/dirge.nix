{
  lib,
  fetchCrate,
  rustPlatform,
  writeShellApplication,
}:
rustPlatform.buildRustPackage (final: {
  pname = "dirge-agent";
  version = "0.25.5";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-W5120+j+ITg6sC73A/eeWlPR9m9VcwDsPA4MGh2Fhwo=";
  };
  cargoHash = "sha256-H1K9h83lokVeoCCDq7f1PSzpm4viuzu/TptxCuBUUxQ=";
  prePatch = "rm -rf .cargo # forces mold";
  nativeBuildInputs = [rustPlatform.bindgenHook];
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
