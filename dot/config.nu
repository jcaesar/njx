let user = (whoami)
let hostname = (hostname)

def njx-fmt-time [t] {
  let u = [[fmt unit];
    [wk 1wk]
    [day 1day]
    [hr 1hr]
    [min 1min]
    [sec 1sec]
    [ms 1ms]
    [us 1us]
  ]
  | where { $t >= $in.unit }
  | first
  | default {fmt: ns, unit: 1ns}
  $t / $u.unit
  | math round -p 1
  | $"($in)($u.fmt)"
}

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
    pre_prompt: [{
      # shell title (and accidentally useful newline)
      print $"\a(ansi title)($user)@($hostname):(pwd) $(ansi st)"
      # prev duration
      # i don't want this reprinted on Ctrl-C
      # it seems I cant (re-)set env vars from the PROMPT_COMMAND
      # so this is not part of the prompt
      let last_dur = $env.CMD_DURATION_MS | into float | $in * 0.001sec
      let durs = if $last_dur > 2sec {
        print $"(ansi purple)(njx-fmt-time $last_dur)(ansi reset)"
      }
      $env.CMD_DURATION_MS = "0"
    }]
    pre_execution: [{ print -n $"(ansi title)(commandline) < ($user)@($hostname):(pwd)(ansi st)" }]
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
  $"(ansi purple)($time) ($scolor) (ansi green)(whoami)@(hostname)(ansi white):(ansi yellow)($dir)(ansi reset)\n$ " }

$env.PATH = (
  $env.PATH
  | where { $in !~ nix.*profile.*bin or ($in | path exists) }
  | append /usr/bin/env
  | uniq
)

# aliases
export def lsm [] { ls | sort-by modified }
export def psf [name] { ps --long | where command =~ $name }
export def sex [str] { $str | str expand }
