# an sftp fileserver - likely one of the lamest configs i have
{
  networking.hostName = "westie";
  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "sr_mod"];
  hardware.cpu.intel.updateMicrocode = true;
  njx.base = true;
  users.users.root.openssh.authorizedKeys.keys = (import ../private.nix).terminalKeys;
  fileSystems."/" = {
    fsType = "btrfs";
    device = "/dev/mapper/nixroot";
    options = ["discard" "compress"];
  };
  fileSystems."/boot" = {
    fsType = "vfat";
    device = "/dev/disk/by-partlabel/nixboot";
  };
  fileSystems."/mnt/data" = {
    fsType = "btrfs";
    device = "/dev/mapper/data";
  };
  boot.initrd.luks.devices.nixroot = {
    device = "/dev/disk/by-label/nixcrypt";
    allowDiscards = true;
  };
  boot.initrd.luks.devices.data = {
    device = "/dev/disk/by-label/data";
  };
  system.stateVersion = "25.11";
}
