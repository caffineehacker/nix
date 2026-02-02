{ config, pkgs, ... }: {
  systemd.network = {
    enable = true;
    netdevs = {
      "50-wgserver" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wgserver";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."wireguard/serverPrivate".path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          {
            # Matrix
            PublicKey = "48/1lPw1HEw2mUh7B7x/el/FJIMN7aWdL7MYZ37p0EA=";
            AllowedIPs = [ "10.100.0.2" ];
          }
          {
            # Home assistant
            PublicKey = "ycVWUoplHEIQdsax3AZNwX9wD+N5MXprsqsSzjNDihA=";
            AllowedIPs = [ "10.100.0.60" ];
          }
        ];
      };
    };
    networks.wgserver = {
      matchConfig.Name = "wgserver";
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

  # Ensure fail2ban doesn't ban the home network
  services.cron =
    let
      allowWgIpScript = pkgs.writeShellApplication
        {
          name = "allow_wg_ip.sh";
          runtimeInputs = [ pkgs.wireguard-tools pkgs.fail2ban ];
          text = ''
            #!/bin/sh
            wg show | grep endpoint | sed 's/.*endpoint: //g' | sed 's/:.*//g' | xargs fail2ban-client unban
          '';
        };
    in
    {
      enable = true;
      systemCronJobs = [
        "0 */5 * * * * root ${allowWgIpScript}/bin/allow_wg_ip.sh"
      ];
    };
}
