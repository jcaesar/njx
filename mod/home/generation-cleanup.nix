{
  lib,
  pkgs,
  config,
  ...
}: {
  home.activation.cleanGenerations = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run ${lib.getExe' pkgs.nix "nix-env"} $VERBOSE_ARG --delete-generations \
      --profile ${config.xdg.stateHome}/nix/profiles/home-manager +1
  '';
}
