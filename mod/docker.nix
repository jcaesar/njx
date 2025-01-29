{
  config,
  lib,
  pkgs,
  ...
}: {
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = lib.mkDefault true;
      setSocketVariable = true;
    };
  };
  # nushell doesn't pick up environment.extraInit. Only one thing there I really need
  home-manager.users.julius.programs.nushell.extraEnv = lib.mkIf config.virtualisation.docker.rootless.enable ''
    # rootless docker socket
    if ("XDG_RUNTIME_DIR" in $env) and not ("DOCKER_HOST" in $env) {
      $env.DOCKER_HOST = $"unix://($env.XDG_RUNTIME_DIR)/docker.sock"
    }
  '';
  users.users.julius.packages = [pkgs.regctl];
}
