{
  config,
  lib,
  ...
}: let
  bootFs = config.fileSystems."/boot";
in {
  boot.initrd.secrets = lib.mkForce {};
  boot.initrd.systemd.mounts = lib.singleton {
    what = bootFs.device;
    where = "/boot";
    type = bootFs.fsType;
  };
  boot.initrd.network.ssh.hostKeys = lib.mkForce [
    "/boot/leakrets/ssh/host_rsa_key"
    "/boot/leakrets/ssh/host_ed25519_key"
  ];
}
