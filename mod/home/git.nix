{
  pkgs,
  lib,
  ...
}: let
  ghcli = lib.getExe pkgs.github-cli;
  creds = ["" "${ghcli} auth git-credential"];
in {
  programs.git = {
    enable = true;
    difftastic.enable = true;
    ignores = [".*.swp"];
    aliases = {
      l = "log --oneline --decorate --all --graph";
      lg = "log --graph --abbrev-commit --decorate --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      quickserve = "daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths .git/";
    };
    extraConfig = {
      pull.ff = "only";
      rerere.enable = true;
      user.name = "Julius Michaelis";
      delta.nagivate = true; # use n and N to move between diff sections
      "credential \"https://github.com\"".helper = creds;
      "credential \"https://gist.github.com\"".helper = creds;
    };
  };
}
