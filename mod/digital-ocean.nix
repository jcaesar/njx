# "${modulesPath}/virtualisation/digital-ocean-image.nix" exists, but I don't like the resulting image
# .#nixosConfigurations.$host.config.system.build.digitalOceanImage
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = ["${modulesPath}/virtualisation/digital-ocean-config.nix"];
  virtualisation.digitalOcean = {
    setRootPassword = false;
    setSshKeys = false;
    seedEntropy = true;
    rebuildFromUserData = false;
  };
  services.smartd.enable = false;

  system.build.digitalOceanImage = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit config lib pkgs;
    name = "doggieworld-image";
    format = "qcow2";
    configFile = null;
    diskSize = "auto";
    partitionTableType = "hybrid";
    copyChannel = false;
  };

  njx.protect-boot = false;
  # boot.loader.grub.device = "/dev/vda"; # somehow default
  boot.loader.grub.enable = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  boot.kernelParams = lib.mkForce ["loglevel=4"]; # default sets console=ttyS0, but DO doesn't have a serial console
  hardware.firmware = lib.mkForce []; # huge hog and unnecessary
}
