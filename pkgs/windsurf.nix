pkgs:
pkgs.windsurf.overrideAttrs (prev: {
  postInstall = ''
    ${prev.postinstall or ""}
    ln -s ${pkgs.vscode}/lib/vscode/bin/code-tunnel $out/lib/windsurf/bin/windsurf-tunnel
    test -e $out/lib/windsurf/bin/windsurf-tunnel
  '';
})
