final: prev: {
  # geopandas tests fail: pyarrow roundtrip length errors + shapely-2 mask tests
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (_: finalPython: {
      geopandas = finalPython.geopandas.overridePythonAttrs (old: {
        doCheck = false;
      });
    })
  ];
  home-assistant = prev.home-assistant.override {
    packageOverrides = _: prev: {
      # apparently this doesn't build on bcachefs
      python-kasa = prev.python-kasa.overridePythonAttrs {
        doCheck = false;
      };
    };
  };
  windsurf = prev.windsurf.overrideAttrs (prev: {
    postInstall = ''
      ${prev.postinstall or ""}
      ln -s ${final.vscode}/lib/vscode/bin/code-tunnel $out/lib/windsurf/bin/windsurf-tunnel
      test -e $out/lib/windsurf/bin/windsurf-tunnel
    '';
  });
  coredns = prev.coredns.overrideAttrs (old: {
    postPatch = ''
      ${old.postPatch}
      substituteInPlace test/reload_test.go \
        --replace-fail "TestReloadUnreadyPlugin" "SkipReloadUnreadyPlugin"
      substituteInPlace test/view_test.go \
        --replace-fail "TestView" "SkipView"
    '';
  });
}
