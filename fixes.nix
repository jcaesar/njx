final: prev: {
  home-assistant = prev.home-assistant.override {
    packageOverrides = _: prev: {
      # apparently this doesn't build on bcachefs
      python-kasa = prev.python-kasa.overridePythonAttrs {
        doCheck = false;
      };
    };
  };
  libselinux = prev.libselinux.overrideAttrs (orig: if final.stdenv.hostPlatform.isStatic then {
    patches =
      final.lib.singleton "${builtins.fetchTree "github:NixOS/nixpkgs/a1d539f8eecffd258f3ed1ccc3a055aed56fbaa1"}/pkgs/by-name/li/libselinux/fix-build-32bit-lfs.patch"
      ++ final.lib.filter (x: builtins.match ".*fix-build-32bit-lfs.patch" "${x}" == null) orig.patches;
  } else {});
}
