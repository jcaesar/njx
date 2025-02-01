{
  runCommand,
  nushell,
}:
runCommand "njx-repo-scripts" {
  buildInputs = [nushell];
}
''
  for f in ${./.}/*.nu; do
    install -Dt $out/bin "$f"
  done
  patchShebangs $out/bin
''
