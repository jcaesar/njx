{
  lib,
  paramiko,
  rustworkx,
  pynacl,
  tqdm,
  nix,
  buildPythonApplication,
}:
buildPythonApplication {
  pname = "njx";
  version = "0.1.0";
  propagatedBuildInputs = [paramiko rustworkx pynacl tqdm];
  src = ./.;
  format = "other";
  installPhase = ''
    install -D ${./.}/installed.py $out/bin/njx-installed
    install -D ${./.}/delete_generations.py $out/bin/njx-delete-generations
    for f in $out/bin/njx-{installed,delete-generations}; do
      wrapProgram $f --suffix PATH : ${lib.makeBinPath [nix]}
    done
  '';
}
