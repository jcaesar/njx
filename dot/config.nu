let load_direnv = {
  if (which direnv | is-empty) { return }
  direnv export json | from json | default {} | load-env
}
let user = (whoami)
let hostname = (hostname)

let external_completer = {|spans|

  let fish_completer = {|spans|
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | $"value(char tab)description(char newline)" + $in
    | from tsv --flexible --no-infer
    | each {|r|
        if (" " in $r.value) and not ("`" in $r.value) {
          $r | update value $"`($r.value)`"
        } else {
          $r.value
        }
      }
  }

  let expanded_alias = scope aliases
  | where name == $spans.0
  | get -o 0.expansion

  let spans = if $expanded_alias != null {
    $spans
    | skip 1
    | prepend ($expanded_alias | split row ' ' | take 1)
  } else {
    $spans
  }

  do $fish_completer $spans
}

$env.config = {
  show_banner: false,
  history: {
    file_format: "sqlite"
    isolation: true
  }
  completions: {
    external: {
      enable: true
      completer: $external_completer
    }
  }
  hooks: {
    pre_prompt: [{ print -n $"\a(ansi title)($user)@($hostname):(pwd) $(ansi st)" }]
    pre_execution: [
      { print -n $"(ansi title)($user)@($hostname):(pwd) > (commandline)(ansi st)" }
      $load_direnv
    ]
    env_change: {
      PWD: [{|before, after| do $load_direnv }]
    }
  }
  float_precision: 6, # https://xkcd.com/2170/
}
$env.PATH = (
  $env.PATH |
  split row (char esep) |
  append /usr/bin/env
)

# aliases
export def lsm [] { ls | sort-by modified }
export def psf [name] { ps --long | where command =~ $name }
