#!/usr/bin/env nu

def main [] {
  git tag 
  | lines | parse "{machine}-{rev}"  | group-by machine 
  | items {|machine, revs| 
    let tag = $"($machine)-($revs.rev | into int | math max)"
    let rev = (git rev-list -n1 $tag | cut -c-7)
    let lock = (git show $"($tag):flake.lock" | from json)
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
      tag: (git tag --format '%(*authordate)' -n1 $tag | into datetime),
    } | merge ($dates | transpose -rid)
  } | sort-by --reverse nixpkgs tag
}
