{ config, pkgs, ... }: {
  systemd.network = {
    enable = true;
    netdevs = {
      "50-matrixwg" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "matrixwg";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."matrix/wireguard/serverKey".path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          {
            PublicKey = "48/1lPw1HEw2mUh7B7x/el/FJIMN7aWdL7MYZ37p0EA=";
            AllowedIPs = [ "10.100.0.2" ];
          }
        ];
      };
    };
    networks.matrixwg = {
      matchConfig.Name = "matrixwg";
      address = [
        "10.100.0.1/24"
      ];
      networkConfig = {
        IPMasquerade = "ipv4";
        IPv4Forwarding = true;
        IPv6Forwarding = true;
      };
    };
  };
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

  environment.systemPackages = with pkgs; [ wireguard-tools ];
}
