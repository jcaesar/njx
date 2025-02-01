{modulesPath, ...}: let
  mkModOption = name: {
    lib,
    config,
    pkgs,
    ...
  } @ args: {
    options.njx.${name} = lib.mkEnableOption "/mod/${name}.nix";
    config = lib.mkIf config.njx.${name} (import ./${name}.nix args);
  };
in {
  config.hardware.nvidia.open = false; # https://github.com/NixOS/nixpkgs/pull/337289#issuecomment-2313802016
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    ./variants.nix
    ./ssh-unlock.nix
    ./wg-doggieworld.nix
    ./manual.nix
    ./powercap.nix
    ./common-home-nushell-env.nix
    ./source-flakes.nix
    ./extra-initrd.nix
    (mkModOption "base")
    (mkModOption "binfmt")
    (mkModOption "bluetooth")
    (mkModOption "common")
    (mkModOption "dlna")
    (mkModOption "firefox/default")
    (mkModOption "graphical")
    (mkModOption "prometheus-nvml-exporter")
    (mkModOption "pi3")
    (mkModOption "docker")
    (mkModOption "seeed-2mic/default")
    (mkModOption "slim")
    (mkModOption "sysrq")
  ];
}
