{
  pkgs,
  nixosConfig,
  ...
}: {
  # Stolen from https://wiki.nixos.org/wiki/Nushell
  programs = {
    nushell = {
      enable = true;
      package = pkgs.nushell;
      configFile.source = ../../dot/config.nu;
      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
      };
      # workaround for there not being nushell support for environment.variables
      extraEnv = ''
        mut cev = open ${pkgs.writeText "environment.variables.json" (builtins.toJSON nixosConfig.environment.variables)}
        for var in [XCURSOR_PATH XDG_CONFIG_DIRS XDG_DATA_DIRS PATH] {
          if $var in $cev and $var in $env {
            let merge = [$cev $env]
              | each { get $var | split row ":" }
              | flatten
              | uniq
              | str join ":"
            $cev = $cev | update $var $merge
          }
        }
        $cev | load-env
      '';
    };
    starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        add_newline = true;
        scan_timeout = 5;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        aws.disabled = true;
        directory.truncate_to_repo = false;
        nix_shell.heuristic = true;
        hostname.ssh_only = false;
      };
    };
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
}
