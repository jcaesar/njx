{config, ...}: {
  njx.base = true;
  njx.bpir4 = true;
  system.stateVersion = config.system.nixos.release;
}
