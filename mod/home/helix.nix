{
  pkgs,
  lib,
  ...
}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "gruvbox";
      editor = {
        auto-pairs = false;
        auto-completion = false;
        auto-save = true;
        bufferline = "multiple";
        true-color = true;
        lsp.display-messages = true;
        soft-wrap.enable = true;
      };
      keys.normal."C-s" = "split_selection_on_newline";
    };
    languages = {
      language = [
        {
          name = "java";
          indent = {
            tab-width = 4;
            unit = "    ";
          };
        }
        {
          name = "nix";
          language-servers = ["nixd"];
        }
        {
          name = "markdown";
          language-servers = ["ltex-ls-plus"];
          # markdown-oxide is dumb as a brick (recognizes # in code blocks as sections)
          # marksman will pull in a .net
        }
      ];
      language-server = {
        nixd.command = lib.getExe pkgs.nixd;
        ltex-ls-plus.command = lib.getExe pkgs.ltex-ls-plus;
        ltex-ls-plus.args = ["%{buffer_name}"];
      };
    };
    extraPackages = let
      p = with pkgs; [rust-analyzer rustfmt];
      pp = with pkgs.python3.pkgs; [python-lsp-server python-lsp-ruff];
    in
      p ++ pp;
  };
}
