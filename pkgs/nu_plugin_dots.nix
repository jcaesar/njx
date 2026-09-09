{
  pkgs,
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
  nativeBuildInputs = [pkgs.nushell];
  propagatedBuildInputs = [contextily geopandas];
  installPhase = ''
    install -Dm555 ${../mod/home/nu/nu_plugin_dots.py} $out/bin/${finalAttrs.pname}
  '';
  doCheck = true;
  checkPhase = ''
    mkdir -p "$NIX_BUILD_TOP/nucfg"
    export XDG_CONFIG_HOME="$NIX_BUILD_TOP/nucfg"
    nu -c '
      plugin add ($env.out)/bin/nu_plugin_dots
      plugin use dots
      let pts = [[lon lat]; [1 2] [3 4] [5 6]]
      let svg = $pts | dots --no-basemap
      assert ($svg | str contains "<svg")
    ' 
  '';
})
