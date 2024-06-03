{...}: {
  # ...
  services.caddy = {
    enable = true;
    virtualHosts."matrix.timwaterhouse.com".extraConfig = ''
      reverse_proxy /_matrix/* 10.100.0.2:8008
      reverse_proxy /_synapse/client/* 10.100.0.2:8008
    '';
    virtualHosts."matrix.timwaterhouse.com:8448".extraConfig = ''
      reverse_proxy /_matrix/* 10.100.0.2:8008
    '';
    email = "tim@timwaterhouse.com";
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 8448 ];
  };
}