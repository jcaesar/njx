{
  buildPythonApplication,
  emptyDirectory,
  python,
  contextily,
  geopandas
}:
buildPythonApplication (finalAttrs: {
  pname = "nu_plugin_dots";
  version = "0.0.1";
  format = "other";
  src = emptyDirectory;
  propagatedBuildInputs = [contextily geopandas];
  installPhase = ''
    install -Dm555 ${../mod/home/nu/nu_plugin_dots.py} $out/bin/${finalAttrs.pname}
  '';
})
