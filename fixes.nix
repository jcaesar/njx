final: prev: {
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
}
