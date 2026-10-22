{config, ...}: {
  njx.base = true;
  njx.toriaezu-btrfs = true;
  system.stateVersion = config.system.nixos.release;
}
