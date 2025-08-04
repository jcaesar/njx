#!/usr/bin/env nu

def main [target: string] {
  # cd $env.FILE_PWD # Hmm todo. maybe we can get the flake metadata some other way, pass it in from apps?
  let flakemeta = nix flake metadata --json | from json
  let flakepath = $"path:($flakemeta.path)?($flakemeta.locked | reject -o __final ref type url dirtyRev dirtyShortRev | url build-query)"
  let sshopts = [-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60]
  $env.NIX_SSHOPTS = $sshopts | str join " "

  nix copy --to ssh://($target) $flakemeta.path
  ssh -tt ...$sshopts $target nh os switch -Ra $"'($flakepath)'"
}
