# This is based on a mix of
# - https://gitlab.com/K900/nix/-/blob/fa6dd56dda3582e4c69f95c63986a2c92ada5734/shared/platform/bpi-r4.nix
# - https://github.com/nakato/nixos-sbc/blob/816476f7c151d6170c74d655759f77641411372a/modules/boards/bananapi/bpir4/sd-image-mt7988.nix
# The former wants to install uboot to spi and then boot like it's just any other efi. Neat, but I never managed to get that to work (It's described at https://github.com/nim65s/dotfiles/tree/374ca7d361cc1aa2ba4f2e5bc47c58c83b15f672/machines/bpi-r4 but the SPI is split into two parts when I look at it and the uboot image won't fit.)
# The latter is out of date, doesn't build on master, and the resulting sd image doesn't boot even with an old commit
# Personally, I prefer the "create an sd card once, it boots" thing. I know it's at odds with the "treat u-boot as firmware, like efi on x86" stance.
# In the off case I do want nvme, I can just move the root partition later.
{
  pkgs,
  config,
  lib,
  ...
}: let
  pkgsCross = config.system.build.argsCross.x86_64-linux.pkgs;
  pkgsBuild = pkgsCross.pkgsBuildBuild;

  uboot = pkgsCross.buildUBoot {
    src = fetchTree {
      type = "github";
      owner = "K900";
      repo = "u-boot";
      # ref = "refs/heads/bpi-r4";
      rev = "edf28fba63af6a97222f57551ae6d5b7a8e75527";
    };
    version = "2025.07-bpi";
    defconfig = "mt7988a_bananapi_bpi-r4-bootstd_defconfig";
    filesToInstall = ["u-boot.bin"];
    extraConfig = ''
      CONFIG_AUTOBOOT=y
      CONFIG_BOOTDELAY=1
      CONFIG_USE_BOOTCOMMAND=y
      CONFIG_BOOTSTD_DEFAULTS=y
      CONFIG_BOOTSTD_FULL=y
      CONFIG_CMD_BOOTFLOW_FULL=y
      CONFIG_BOOTCOMMAND="bootflow scan -lb"
      CONFIG_ENV_IS_NOWHERE=y
      CONFIG_LZ4=y
      CONFIG_BZIP2=y
      CONFIG_ZSTD=y
      CONFIG_CMD_EXT4=y
      CONFIG_FS_BTRFS=y
      CONFIG_CMD_BTRFS=y
      CONFIG_BOOTP_PXE=n
    '';
  };

  tfA = pkgsCross.buildArmTrustedFirmware {
    platform = "mt7988";
    extraMakeFlags = [
      "BL33=${uboot}/u-boot.bin" # FIP-ify our uboot
      "BOOT_DEVICE=sdmmc" # boot from SD
      "DRAM_USE_COMB=1" # you're supposed to use this one, sayeth mediatek
      "DDR4_4BG_MODE=0" # disable large RAM support, for some reason this breaks things
      "USE_MKIMAGE=1" # use uboot mkimage instead of vendor mtk tool
      "bl2"
      "fip"
    ];
    filesToInstall = [
      "build/mt7988/release/bl2.img"
      "build/mt7988/release/fip.bin"
    ];
  };

  tfA' = tfA.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "mtk-openwrt";
      repo = "arm-trusted-firmware";
      rev = "e090770684e775711a624e68e0b28112227a4c38";
      hash = "sha256-VI5OB2nWdXUjkSuUXl/0yQN+/aJp9Jkt+hy7DlL+PMg=";
    };
    nativeBuildInputs =
      old.nativeBuildInputs
      ++ (with pkgs.pkgsBuildBuild; [
        dtc
        openssl
        ubootTools
        which
      ]);
  });

  kernel = pkgsCross.buildLinux {
    version = "7.0.9";
    modDirVersion = "7.0.9";
    src = fetchTree {
      type = "github";
      owner = "K900";
      repo = "linux";
      # ref = "refs/heads/bpi-r4";
      rev = "97371ad31bdb8d1c5c052d5dcc2e95bb6fc207cf";
    };

    kernelPatches = [
      {
        name = "fix-build-with-phylink-builtin";
        patch = null;
        structuredExtraConfig = {
          FWNODE_PCS = lib.kernel.yes;
          PCS_MTK_USXGMII = lib.kernel.yes;
        };
      }
    ];
  };

  nixos-sbc = fetchTree {
    type = "github";
    owner = "nakato";
    repo = "nixos-sbc";
    rev = "816476f7c151d6170c74d655759f77641411372a";
  };
in {
  nixpkgs.system = "aarch64-linux";

  system.boot.loader.kernelFile = "Image";
  boot = {
    kernelPackages = pkgsCross.linuxPackagesFor kernel;
    kernelParams = ["clk_ignore_unused" "cma=256M"];
    consoleLogLevel = 7;

    initrd.kernelModules = [
      "mmc_block"
      "pcie-mediatek-gen3"
      "mii"
    ];
    initrd.availableKernelModules = ["nvme" "mtk_eth" "mt7530_mmio" "tag_mtk"]; # insufficient for networking, but I'll figure that out later

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  hardware = {
    firmware = [pkgs.linux-firmware];
    deviceTree.filter = "mt7988a-bananapi-bpi-r4.dtb";
    deviceTree.overlays = lib.singleton {
      name = "bpi-r4-emmc";
      dtsFile = "${nixos-sbc}/modules/boards/bananapi/bpir4/mt7988a-bananapi-bpi-r4-sd.dts";
      # depending on how you set the dip switches, the internal emmc or the sd card appears at the hardware address, and you can't have both (I think. dipswitchdipshit)
      # anyway, make sure this is the dts for the sd card. the k900 one has the emmc one.
    };
  };

  fileSystems."/" = {
    fsType = "btrfs";
    device = "/dev/mapper/sdnixroot";
    options = ["discard" "compress=zstd:12"];
  };
  fileSystems."/boot" = {
    fsType = "vfat";
    device = "/dev/disk/by-label/sdnixboot";
  };
  njx.protect-boot = false;
  boot.initrd.luks.devices.sdnixroot = {
    device = "/dev/disk/by-label/sdnixcrypt";
    allowDiscards = true;
  };

  system.build.formatSd = pkgsBuild.writeShellApplication {
    name = "format-bpir4-sd";
    runtimeInputs = with pkgsBuild; [coreutils btrfs-progs cryptsetup gptfdisk e2fsprogs util-linux nix coreutils dosfstools systemd shadow];
    inheritPath = false;
    text = ''
      dst="''${1?Specify target mmcblk as first argument}"
      mnt="''${2?Specify root mount target as second argument}"
      bl2="$(uuidgen)"
      fip="$(uuidgen)"
      boot="$(uuidgen)"
      root="$(uuidgen)"
      bpu=/dev/disk/by-partuuid
      chroot=${lib.getExe' pkgs.coreutils "chroot"}
      emu=${pkgs.stdenv.hostPlatform.emulator pkgsBuild}
      sys=/nix/var/nix/profiles/system
      export LC_ALL=C.UTF-8
      set -x
      sgdisk --clear --zap-all "$dst" || true
      dd if=/dev/zero of="$dst" bs=4M count=5
      # wat's a disco?
      sgdisk --set-alignment=2 \
        -n 1:34:+500k -c 1:bl2 -A 1:set:2:1 -u 1:"$bl2" \
        -n 2::+2M -c 2:fip -u 2:"$fip" \
        -n 5:4M:699M -c 5:boot -A 5:set:2 -u 5:"$boot" \
        -n 6:700M: -c 6:root -u 6:"$root" \
        "$dst"
      udevadm settle
      if ! test -e "$bpu/$root"; then
        echo Creating paritions succeded but the kernel doesn\'t show them.
        echo If you losetup\'d this, pass -P
        exit 1
      fi
      bl2="$(realpath "$bpu/$bl2")"
      fip="$(realpath "$bpu/$fip")"
      boot="$(realpath "$bpu/$boot")"
      root="$(realpath "$bpu/$root")"
      dd conv=notrunc if=${tfA'}/bl2.img of="$bl2"
      dd conv=notrunc if=${tfA'}/fip.bin of="$fip"
      cryptsetup luksFormat "$root" --label sdnixcrypt --verify-passphrase \
      || echo Did not luksFormat - will try to open it anyway, maybe it already exists
      cryptsetup luksOpen "$root" sdnixroot --allow-discards
      mkfs.btrfs /dev/mapper/sdnixroot \
      || echo Making btrfs failed, likely because luksFormat was skipped and it already exist. Continuing.
      mount /dev/mapper/sdnixroot "$mnt" -ocompress=zstd:19,discard
      mkdir -p "$mnt"/boot
      mkfs.fat -F32 -nsdnixboot "$boot"
      mount "$boot" "$mnt"/boot
      nix-env --extra-substituters auto?trusted=1 --store "$mnt" -p "$mnt/$sys" --set ${config.system.build.toplevel}
      # shellcheck disable=SC2174
      mkdir -p -m755 "$mnt"/etc
      $emu $chroot "$mnt" "$sys"/activate # creates os-release and other stuff that the bootloader installer requires
      passwd -R "$mnt" root
      $emu $chroot "$mnt" "$sys"/bin/switch-to-configuration boot
      umount -R "$mnt"
      cryptsetup luksClose /dev/mapper/sdnixroot
    '';
  };
}
