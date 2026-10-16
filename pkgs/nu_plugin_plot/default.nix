{
  lib,
  buildPythonApplication,
  emptyDirectory,
  contextily,
  geopandas,
  nushell,
  writeScriptBin,
}:
buildPythonApplication (finalAttrs: {
  pname = "nu_plugin_plot";
  version = "0.0.1";
  format = "other";
  src = emptyDirectory;
  nativeBuildInputs = [nushell];
  propagatedBuildInputs = [contextily geopandas];
  installPhase = ''
    ob=$out/bin/${finalAttrs.pname}
    install -Dm555 ${./plot.py} $ob
    substituteInPlace $ob --replace-fail '"version": NUSHELL_VERSION' '"version": "${nushell.version}"'
  '';
  postFixup = "nu -c 'plugin add --plugin-config ($env.out)/registry.msgpackz ($env.out)/bin/${finalAttrs.pname}'";
  doCheck = true;
  checkPhase = ''
    nu -c '
      plugin use --plugin-config '$out'/registry.msgpackz plot
      let pts = [[lon lat]; [1 2] [3 4] [5 6]]
      let svg = $pts | plot dots --no-basemap true
      if ($svg | str contains "<svg" | not $in) {
        exit 1
      }
    '
  '';
})
