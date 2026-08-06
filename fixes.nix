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

  # https://github.com/NixOS/nixpkgs/issues/548631#issuecomment-5203175176
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ prev.lib.singleton (final: prev: {
      python-lsp-ruff = prev.python-lsp-ruff.overridePythonAttrs (old: {
        disabledTests =
          (old.disabledTests or [])
          ++ [
            "test_ruff_settings"
            "test_notebook_input"
          ];
      });
    });
}
