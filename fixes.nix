final: prev: {
  home-assistant = prev.home-assistant.override {
    packageOverrides = _: prev: {
      # apparently this doesn't build on bcachefs
      python-kasa = prev.python-kasa.overridePythonAttrs {
        doCheck = false;
      };
    };
  };
  etcd = prev.etcd.override {
    buildGoModule = a: final.buildGoModule (a // {doCheck = false;});
  };
}
