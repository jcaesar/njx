{pkgs, ...}: {
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
      ];
      language-server.nixd.command = "${pkgs.nixd}/bin/nixd";
    };
    extraPackages = let
      p = with pkgs; [rust-analyzer rustfmt];
      pp = with pkgs.python3.pkgs; [python-lsp-server python-lsp-ruff];
    in
      p ++ pp;
  };
}
