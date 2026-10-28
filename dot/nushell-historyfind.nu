$env.config.keybindings = $env.config.keybindings | append {
  name: fuzzy_history
  modifier: control
  keycode: char_r
  mode: [emacs, vi_normal, vi_insert]
  event: [
    {
      send: ExecuteHostCommand
      cmd: "do {
        commandline edit --insert (
          history
          | get command
          | reverse
          | uniq
          | str join (char -i 0)
          | @FINDER@ 
              --read0 --print0
              --layout=reverse
              --height=40%
              --preview='exec @PREVIEW@ {}'
          | bytes split 0x[0] | get 0
          | decode utf8
        )
      }"
    }
  ]
}
