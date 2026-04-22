{
  buildPythonApplication,
  emptyDirectory,
  pandas,
}:
buildPythonApplication (finalAttrs: {
  pname = "mini-example";
  version = "0.0.1";
  format = "other";
  src = emptyDirectory;
  propagatedBuildInputs = [pandas];
  installPhase = ''
    install -Dm555 ${./script.py} $out/bin/${finalAttrs.pname}
  '';
})
