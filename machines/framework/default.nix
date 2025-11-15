{ ... }: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./logiops.nix
    ./plymouth.nix
  ];
}
