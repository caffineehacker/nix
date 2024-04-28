{pkgs, ...}: {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = ["root" "tim"];
    settings.show-trace = true;
  };

  nixpkgs.hostPlatform = {
    system = "aarch64-linux";
  };

  imports = [
    ../common.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "homeauto";

  hardware.enableRedistributableFirmware = true;
  networking.wireless.enable = true;

  boot.initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];

  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages;
}