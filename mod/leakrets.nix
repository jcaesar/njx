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
    requiredBy = ["sshd.service"];
    before = ["sshd.service"];
    mountConfig = lib.mkIf (config.njx.protect-boot) {
      # You'd think this doesn't matter in initrd, but sshd is a stickler
      Options = "umask=0077";
    };
  };
  boot.initrd.network.ssh.hostKeys = lib.mkForce [
    "/boot/leakrets/ssh/host_rsa_key"
    "/boot/leakrets/ssh/host_ed25519_key"
  ];
}
