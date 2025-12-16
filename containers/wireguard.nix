{ lib, config, ... }:
let
  cfg = config.tw.containers.wireguard;
in
{
  options = {
    tw.containers.wireguard.enable = lib.mkEnableOption "wireguard";

    tw.containers.wireguard.port = lib.mkOption {
      type = lib.types.int;
      default = null;
      example = "8080";
      description = "The service port number";
    };

    tw.containers.wireguard.tunnelIp = lib.mkOption {
      type = lib.types.str;
      default = null;
      example = "10.100.0.2";
      description = "The IP address for the tunnel endpoint";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];
    systemd.network = {
      enable = true;
      netdevs = {
        "10-wg0" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "wg0";
            MTUBytes = "1300";
          };
          wireguardConfig = { };
          wireguardPeers = [
            {
              PublicKey = "ecv9aiMiBB4FymTEjN+VMMAYJVaFUvUkBUTp8CIfhRo=";
              AllowedIPs = [ "10.100.0.1" ];
              Endpoint = "129.153.214.198:51820";
              PersistentKeepalive = 5;
            }
          ];
        };
      };
      networks.wg0 = {
        matchConfig.Name = "wg0";
        address = [
          "${cfg.tunnelIp}/24"
        ];
        DHCP = "no";
        routes = [
          {
            Destination = "10.100.0.1/24";
            Gateway = "10.100.0.1";
          }
        ];
        networkConfig = {
          IPv6AcceptRA = false;
        };
      };
    };
  };
}
