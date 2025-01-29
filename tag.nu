#!/usr/bin/env nu

def tag [hostname: string] {
  from json | each {|l|
    if $l.configurationRevision != "" and $l.configurationRevision !~ "-dirty" {
      let tag = $"($hostname)-($l.generation)"
      let rev = (do { git rev-parse $"refs/tags/($tag)" } | complete | get exit_code)
      if $rev == 128 {
        let desc = ($l | select date generation kernelVersion nixosVersion | to yaml)
        let tagres = (git tag -a -m $desc $tag $l.configurationRevision | complete)
        let str = $"($tag) -> ($l.configurationRevision)"
        if $tagres.exit_code == 0 {
          return $"($str) created"
        } else {
          return $"Failed to tag ($str)"
        }
      }
    }
  }
}

def main [host?: string] {
  if ($host == null) {
    nixos-rebuild --no-build-nix list-generations --json | complete | get stdout | tag (hostname)
  } else {
    ssh -q $host nixos-rebuild --no-build-nix list-generations --json | complete | get stdout | tag (ssh -q $host hostname)
  }
}
