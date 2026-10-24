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
  coredns = prev.coredns.overrideAttrs (old: {
    postPatch = ''
      ${old.postPatch}
      substituteInPlace test/reload_test.go \
        --replace-fail "TestReloadUnreadyPlugin" "SkipReloadUnreadyPlugin"
      substituteInPlace test/view_test.go \
        --replace-fail "TestView" "SkipView"
    '';
  });
  # https://github.com/NixOS/nixpkgs/pull/577208/changes
  brotli = let new = (prev.brotli.overrideAttrs (old: {
    version = "1.2.1";
    src = final.fetchFromGitHub {
      owner = "google";
      repo = "brotli";
      tag = "v1.2.1";
      hash = "sha256-llY72cYffDv0ugsH0p89xIPEbElV4L8u7U/Fe8hT3gI=";
    };
  })); in new // {overrideAttrs = _: new;};
}
