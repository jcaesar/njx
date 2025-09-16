final: prev: {
  home-assistant = prev.home-assistant.override {
    packageOverrides = _: prev: {
      # apparently this doesn't build on bcachefs
      python-kasa = prev.python-kasa.overridePythonAttrs {
        doCheck = false;
      };
    };
  };
  wasmtime = prev.wasmtime.overrideAttrs (old: {
    postInstall =
      if prev.hostPlatform.isStatic
      then ''
        touch $out/lib/foo.so
        ${old.postInstall}
      ''
      else old.postInstall;
  });
}
