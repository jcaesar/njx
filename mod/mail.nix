{
  lib,
  pkgs,
  ...
}: {
  users.users.julius.packages = with pkgs; [
    # (himalaya.override {buildFeatures = ["maildir"];}) # dropped notmuch support and maildir can't handle 20k emails in the inbox
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
  # https://github.com/RaitoBezarius/nixos-home/blob/main/emails/neomutt.nix
  home-manager.users.julius = {
    programs.neomutt = {
      enable = true;
      sidebar.width = 40;
      sidebar.enable = true;
      sidebar.shortPath = true;
      sidebar.format = "%D%> %?N?%N/?%S";
      vimKeys = true;
      sort = "reverse-date";
      extraConfig = ''
        set nm_default_url = "notmuch:///home/foo/maildir"
        named-mailboxes "My INBOX" "notmuch://?query=tag:inbox"
      '';
    };
  };
}
