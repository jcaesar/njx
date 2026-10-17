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
      let svg2 = [1 2 3 4 5] | plot lines
      if ($svg2 | str contains "<svg" | not $in) {
        exit 1
      }
    '
  '';
  passthru = {
    # use e.g. as echo '[{"lon":139, "lat":42}]' | nix run -- .#nu_plugin_plot.run dots --no-basemap=true
    run = writeScriptBin "nu-plugin-plot-run" ''
      #!${lib.getExe nushell} --stdin
      def main [sc] {
        let data = $in | from json
        plugin use --plugin-config ${finalAttrs.finalPackage.out}/registry.msgpackz plot
        match $sc {
          dots => { $data | plot dots --no-basemap=true }
          lines => { $data | plot lines }
          _ => { error make {msg: "unknown subcommand", labels: [{span: (metadata $sc).span}]} }
        }
      }
    '';
  };
})
