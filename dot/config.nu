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
      { print -n $"(ansi title)($user)@($hostname):(pwd) > (commandline)(ansi st)" }
    ]
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
