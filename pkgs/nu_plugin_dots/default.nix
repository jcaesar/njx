{
  pkgs,
  buildPythonApplication,
  emptyDirectory,
  contextily,
  geopandas,
}:
buildPythonApplication (finalAttrs: {
  pname = "nu_plugin_dots";
  version = "0.0.1";
  format = "other";
  src = emptyDirectory;
  nativeBuildInputs = [pkgs.nushell];
  propagatedBuildInputs = [contextily geopandas];
  installPhase = "install -Dm555 ${./dots.py} $out/bin/${finalAttrs.pname}";
  postFixup = "nu -c 'plugin add --plugin-config ($env.out)/registry.msgpackz ($env.out)/bin/${finalAttrs.pname}'";
  doCheck = true;
  checkPhase = ''
    nu -c '
      plugin use --plugin-config '$out'/registry.msgpackz dots
      let pts = [[lon lat]; [1 2] [3 4] [5 6]]
      let svg = $pts | dots --no-basemap true
      if ($svg | str contains "<svg" | not $in) {
        exit 1
      }
    '
  '';
})
