#!/usr/bin/env nu

def checkrepo [repo: string] {
  let machines = nix eval --json $'($repo)#nixosConfigurations' --apply builtins.attrNames | from json
  git -C $repo tag 
  | lines
  | parse "{machine}-{rev}"
  | where machine in $machines
  | group-by machine 
  | items {|machine, revs| 
    let tag = $"($machine)-($revs.rev | into int | math max)"
    let rev = (git -C $repo rev-list -n1 $tag | cut -c-7)
    let lock = (git -C $repo show $"($tag):flake.lock" | from json)
    let dates = ($lock 
      | get nodes 
      | items {|k, v|
        if "locked" in $v { 
          {input: $k, date: ($v.locked.lastModified * 10 ** 9 | into datetime )} 
        } 
      }
      | where { $in != null }
    ) 
    {
      machine: $machine,
      rev: $rev,
      tag: (git -C $repo tag --format '%(*authordate)' -n1 $tag | into datetime),
    } | merge ($dates | transpose -rid)
  }
}

def main [...repo: string] {
  $repo | each { checkrepo $in } | flatten | sort-by --reverse nixpkgs tag
}
