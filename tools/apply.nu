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
  let srcs = nix flake archive --dry-run --json $target.flake
    | from json | allv { do -i { get path } }
  let sshopts = [-q -oCompression=yes -oControlMaster=auto -oControlPath=/tmp/ssh-check-nix-build-%C -oControlPersist=60]
  $env.NIX_SSHOPTS = $sshopts | str join " "

  if $throughcache {
    let local = ((sys host).hostname == $target.host);
    let th = match $local {
      false => (ssh -tt ...$sshopts $target.host hostname),
      true => $target.host,
    }
    nix copy --to ssh-ng://westie.net.liftm.de ...$srcs --substitute-on-destination --no-check-sigs
    let syspath = ssh ...$sshopts westie.net.liftm.de nix build $"'($flakepath)#nixosConfigurations.($th).config.system.build.toplevel'" --no-link --print-out-paths | lines | first
    if not $local {
      ssh -tt ...$sshopts $target.host nix copy --to local $syspath
      ssh -tt ...$sshopts $target.host nh os $action -R ...($ask) $syspath
    } else {
      nix copy --from https://nix-cache.liftm.de $syspath
      nh os $action ...($ask) $syspath
    }
  } else {
    nix copy --to ssh-ng://($target.host) ...$srcs --substitute-on-destination --no-check-sigs
    ssh -tt ...$sshopts $target.host nh os $action -R ...($ask) $"'($flakepath)'"
  }
}
