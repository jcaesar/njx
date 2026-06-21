let user = (whoami)
let hostname = (hostname)

$env.config = {
  show_banner: false,
  history: {
    file_format: "sqlite"
    isolation: true
  }
  completions: {
    algorithm: "substring"
  }
  hooks: {
    pre_prompt: [{ print -n $"\a(ansi title)($user)@($hostname):(pwd) $(ansi st)" }]
    pre_execution: [
      { print -n $"(ansi title)(commandline) < ($user)@($hostname):(pwd)(ansi st)" }
    ]
  }
  float_precision: 6, # https://xkcd.com/2170/
  shell_integration: { osc2: false }, # do not overwrite pre-exec hook
}
$env.PROMPT_INDICATOR = ""
$env.PROMPT_COMMAND_RIGHT = {|| }
$env.PROMPT_COMMAND = {||
  let time = date now | format date "%H:%M:%S"
  let ec = $env.LAST_EXIT_CODE
  let scolor = if $ec == 0 {
    $"(ansi green)^.^"
  } else if $ec < 128 {
    $"(ansi red)-_-"
  } else {
    $"(ansi xterm_darkorange3a)~.~"
  }
  let dir = pwd
  | str replace $env.HOME ~
  | path split
  | reverse
  | enumerate
  | each {|p|
    let maxl = [80 30 5] | get -o $p.index | default (2);
    if ($p.item | str stats | get unicode-width | $in > $maxl) {
      $"…($p.item | str substring (0 - $maxl)..)"
    } else {
      $p.item
    }
  }
  | reverse
  | path join
  $"\n(ansi purple)($time) ($scolor) (ansi green)(whoami)@(hostname)(ansi white):(ansi yellow)($dir)(ansi reset)\n$ " }
$env.PATH = (
  $env.PATH |
  split row (char esep) |
  append /usr/bin/env
)

# aliases
export def lsm [] { ls | sort-by modified }
export def psf [name] { ps --long | where command =~ $name }
