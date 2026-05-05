{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # boot.initrd.systemd.enable = true;
  # boot.kernelParams = [
  #   "zswap.enabled=1"
  #   "zswap.compressor=lz4"
  #   "zswap.max_pool_precent=40"
  #   "zswap.shrinker_enabled=1"
  # ];

  fileSystems."/" = {
    device = "/dev/mmcblk0p2";
    fsType = "ext4";
  };

  zramSwap.enable = true;

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
