{ ... }: {
  imports = [
    ../common.nix
    ./caddy.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./wireguard.nix
  ];
}
