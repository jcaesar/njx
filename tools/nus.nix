{
  runCommand,
  nushell,
  writeShellApplication,
  njx-repo-scripts,
  lib,
}:
runCommand "njx-repo-scripts" {
  buildInputs = [nushell];
  passthru.apply = flake: let
    info = {inherit (flake.sourceInfo) rev revCount lastModified narHash;};
    script = writeShellApplication {
      name = "njx-apply-${flake.sourceInfo.shortRev}";
      text = ''
        ${lib.getExe' njx-repo-scripts "apply"} \
        ${lib.escapeShellArg (builtins.toJSON info)} \
        "$@"
      '';
    };
  in
    lib.getExe script;
}
''
  for f in ${./.}/*.nu; do
    install -Dt $out/bin "$f"
  done
  patchShebangs $out/bin
''
