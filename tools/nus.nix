{
  runCommand,
  nushell,
}:
runCommand "njx-repo-scripts" {
  buildInputs = [nushell];
}
''
  for f in ${./.}/*.nu; do
    install -D "$f" "$out/bin/njx-$(basename $f .nu)"
  done
  patchShebangs $out/bin
''
