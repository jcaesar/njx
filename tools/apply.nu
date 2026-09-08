#!/usr/bin/env nu

def allv [f] {
  let v = $in
  match ($v | describe -d).type {
    list => { $v }
    record => { $v | values }
    _ => []
  } | each { allv $f } | flatten | append ($v | do $f)
}

def main [--action = "switch", --throughcache, --noask, target: string] {
  let ask = if $noask { [] } else { [-a] }
  let target = $target | parse "{flake}#{host}" | get -o 0 | default {flake: ".", host: $target}

  let flakemeta = nix flake metadata --json $target.flake | from json
  let flakepath = $"path:($flakemeta.path)?($flakemeta.locked | reject -o __final ref type url dirtyRev dirtyShortRev path | url build-query)"
  let srcs = nix flake archive --dry-run --json
    | from json | allv { do -i { get path } }
  let sshopts = [-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60]
  $env.NIX_SSHOPTS = $sshopts | str join " "

  if $throughcache {
    let hostname = ssh ...$sshopts $target.host hostname
    nix copy --to ssh-ng://westiei ...$srcs --substitute-on-destination --no-check-sigs
    let syspath = ssh ...$sshopts westiei nix build $"'($flakepath)#nixosConfigurations.($hostname).config.system.build.toplevel'" --no-link --print-out-paths | lines | first
    ssh -tt ...$sshopts $target.host nix copy --to local $syspath
    ssh -tt ...$sshopts $target.host nh os $action -R ...($ask) $syspath
  } else {
    nix copy --to ssh-ng://($target.host) ...$srcs --substitute-on-destination --no-check-sigs
    ssh -tt ...$sshopts $target.host nh os $action -R ...($ask) $"'($flakepath)'"
  }
}
