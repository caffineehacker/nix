{inputs, ...}:{
  imports = [
    ../common.nix
    inputs.nixos-hardware.nixosModules.raspberryPi3
  ];
}