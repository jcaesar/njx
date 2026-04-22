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
    ignores = [".*.swp"];
    settings = {
      alias = {
        l = "log --oneline --decorate --all --graph";
        lg = "log --graph --abbrev-commit --decorate --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
        quickserve = "daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths.git/";
        out = "log @{u}..";
      };
      pull.ff = "only";
      rerere.enable = true;
      user.name = "Julius Michaelis";
      delta.nagivate = true; # use n and N to move between diff sections
      "credential \"https://github.com\"".helper = creds;
      "credential \"https://gist.github.com\"".helper = creds;
      advice.detachedHead = false;
      # cargo culting https://blog.gitbutler.com/how-git-core-devs-configure-git
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      init.defaultBranch = "default";
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
      help.autocorrect = "prompt";
      commit.verbose = true;
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      merge.conflictstyle = "zdiff3";
    };
  };
  programs.difftastic.enable = true;
  programs.difftastic.git.enable = true;
}
