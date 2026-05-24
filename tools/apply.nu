#!/usr/bin/env nu

def main [--action = "switch", --throughcache, target: string] {
  let target = $target | parse "{flake}#{host}" | get -o 0 | default {flake: ".", host: $target}

  let flakemeta = nix flake metadata --json $target.flake | from json
  let flakepath = $"path:($flakemeta.path)?($flakemeta.locked | reject -o __final ref type url dirtyRev dirtyShortRev | url build-query)"
  let sshopts = [-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60]
  $env.NIX_SSHOPTS = $sshopts | str join " "

  if $throughcache {
    let hostname = ssh ...$sshopts $target.host hostname
    nix copy --to ssh-ng://westiei $flakemeta.path
    let syspath = ssh ...$sshopts westiei nix build $"'($flakepath)#nixosConfigurations.($hostname).config.system.build.toplevel'" --no-link --print-out-paths | lines | first
    ssh -tt ...$sshopts $target.host nix copy --to local $syspath
    ssh -tt ...$sshopts $target.host nh os $action -Ra $syspath
  } else {
    nix copy --to ssh-ng://($target.host) $flakemeta.path
    ssh -tt ...$sshopts $target.host nh os $action -Ra $"'($flakepath)'"
  }
}
