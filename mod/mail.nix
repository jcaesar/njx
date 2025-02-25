{pkgs, ...}: {
  users.users.julius.packages = with pkgs; [
    (himalaya.override {withFeatures = ["notmuch"];})
    (writeScriptBin "notmuch" ''
      #!${runtimeShell}
      export XAPIAN_CJK_NGRAM=1
      exec ${lib.getExe notmuch} "$@"
    '')
    libsecret # for secret-tool
    offlineimap
  ];
  # don't care to put the actual files in here, and don't want age/sops
  home-manager.users.julius.home.file = {
    ".config/himalaya/sample.config.toml".source = ../dot/himalaya.toml;
    ".notmuch-config-sample".source = ../dot/notmuch-config;
    ".offlineimaprc-sample".source = ../dot/offlineimaprc;
  };
  njx.manual.mail = ''
    Un-sample
      * `/home/julius/.config/himalaya/sample.config.toml`
      * `/home/julius/.notmuch-config-sample`
      * `/home/julius/.offlineimaprc-sample`
  '';
}
