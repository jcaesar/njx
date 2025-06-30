# I don't want to keep rebuilding this, so it's pinned to a specific nixos version
pkgs: (builtins.getFlake "github:jcaesar/minimodem/62dcc3c89140be319912a239bc548edc64349f40").packages.${pkgs.system}.web
