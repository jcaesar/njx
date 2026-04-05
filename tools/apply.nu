#!/usr/bin/env nu

def main [--action = "switch", target: string] {
  let target = $target | parse "{flake}#{host}" | get -o 0 | default {flake: ".", host: $target}

  let flakemeta = nix flake metadata --json $target.flake | from json
  let flakepath = $"path:($flakemeta.path)?($flakemeta.locked | reject -o __final ref type url dirtyRev dirtyShortRev | url build-query)"
  let sshopts = [-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60]
  $env.NIX_SSHOPTS = $sshopts | str join " "

  nix copy --to ssh-ng://($target.host) $flakemeta.path
  ssh -tt ...$sshopts $target.host nh os $action -Ra $"'($flakepath)'"
}
