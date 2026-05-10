{ ... }: {
  imports = [
    ../common.nix
    ./alarmdecoder.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./mosquitto.nix
  ];
}
