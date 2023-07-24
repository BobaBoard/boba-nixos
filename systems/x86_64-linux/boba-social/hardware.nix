{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  zramSwap.enable = true;

  boot = {
    loader.grub.device = "/dev/vda";

    cleanTmpDir = true;

    initrd = {
      kernelModules = [ "nvme" ];

      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "xen_blkfront"
        "vmw_pvscsi"
      ];
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/vda1";
      fsType = "ext4";
    };
  };

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 4*1024;
  } ];
}

