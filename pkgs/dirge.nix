{
  lib,
  fetchCrate,
  rustPlatform,
  writeShellApplication,
}:
rustPlatform.buildRustPackage (final: {
  pname = "dirge-agent";
  version = "0.25.7";
  src = fetchCrate {
    inherit (final) pname version;
    hash = "sha256-LHEsPcKCdMlg8wIHzAgfFZe9Cb+mNWivBP9DE9vqdno=";
  };
  cargoHash = "sha256-nMKbBR3VnL85DQQT6LZWr3YOGPVNha0G4yvKbHSPG/E=";
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
