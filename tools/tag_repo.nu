#!/usr/bin/env nu

def tag [repo_input: string, consumer_name: string, commit_input: string, commit_consumer: string, revn_consumer: int] {
  let name = ($consumer_name)-($revn_consumer)-($commit_consumer | str substring 0..5)
  let existing = git -C $repo_input rev-parse $"refs/tags/($name)^{commit}" | complete
  if $existing.exit_code == 0 {
    let $existing = $existing.stdout | str trim
    if $existing != $commit_input {
      print $"Tag ($name) exists but points to ($existing), wanted it to point to ($commit_input)"
      return false
    }
    return true
  }
  let desc = { commit: $commit_consumer, count: $revn_consumer, consumer: $consumer_name } | to yaml
  try {
    git -C $repo_input tag -a -m $desc $name $commit_input
    print $"Created ($name) -> ($commit_input)"
  } catch {
    print $"Failed to tag ($name) -> ($commit_input)"
  }
  return false
}

def repo_name [repo: string] {
  try {
    git -C $repo remote get-url origin
      | str trim | path basename
      | str replace --regex "\\.git$" ""
  } catch {
    $repo | path basename
  }
}

def main [repo_input: string, repo_consumer: string] {
  let repo_input = ($repo_input | path expand)
  let repo_consumer = ($repo_consumer | path expand)
  let consumer_name = repo_name $repo_consumer
  let input_name = repo_name $repo_input
  let btags = git -C $repo_consumer tag -l | lines
  let commits = $btags | par-each {|btag|
    let commit = git -C $repo_consumer rev-list -1 $btag | str trim
    let lock = try { git -C $repo_consumer show $"($commit):flake.lock" | from json } catch { return [] }
    $lock.nodes | items {|input node|
      let rev = $node.locked?.rev?
      match ($input == $input_name and $rev != null) {
        true => [{input: $rev, consumer: $commit }]
        false => []
      }
    } | flatten
  } | flatten | uniq
  let commits = $commits
    | insert revn {|r| git -C $repo_consumer rev-list --count $r.consumer | into int}
    | group-by input | values
    | each { sort-by revn | get 0 }
    | sort-by --reverse revn
  for ci in $commits {
    let abort_early = tag $repo_input $consumer_name $ci.input $ci.consumer $ci.revn
    if $abort_early { break }
  }
}
