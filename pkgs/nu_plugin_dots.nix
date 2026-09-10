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
     export XDG_DATA_HOME="$NIX_BUILD_TOP/ndata"
     mkdir -p "$NIX_BUILD_TOP/ndata"
     echo "HOME=[$HOME] XDG_CONFIG_HOME=[$XDG_CONFIG_HOME] NIX_BUILD_TOP=[$NIX_BUILD_TOP]"
     nu -c 'plugin add ($env.out)/bin/nu_plugin_dots' || echo "ADD FAILED $?"
     echo "--- files after add ---"
     find "$NIX_BUILD_TOP" -type f 2>/dev/null
     nu -c 'plugin use dots' 2>&1 | cat; echo "USE_EXIT=$?"
     nu -c '
       plugin add ($env.out)/bin/nu_plugin_dots
       plugin use dots
       let pts = [[lon lat]; [1 2] [3 4] [5 6]]
       let svg = $pts | dots --no-basemap
       assert ($svg | str contains "<svg")
     '
   '';
})
