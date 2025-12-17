{ ... }: {
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
    virtualHosts."home.timwaterhouse.com".extraConfig = ''
      reverse_proxy 10.100.0.60:8123
    '';
    email = "tim@timwaterhouse.com";
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 8448 ];
  };

  services.fail2ban = {
    enable = true;
    jails = {
      caddy-status = {
        settings = {
          enabled = true;
          port = "http,https";
          filter = "caddy-status";
          logpath = "/var/log/caddy/access*.log";
          backend = "auto";
          maxretry = 10;
        };
      };
    };
  };
  # This regex ignores all json and ensures we're not in a string when we find the remote_ip and status fields
  environment.etc."fail2ban/filter.d/caddy-status.local" = {
    text = ''
      [Definition]
      failregex = ^([^"]|"([^"]|\\")*")*"remote_ip":"<ADDR>"([^"]|"([^"]|\\")*")*"status":(0|403|404)([^"]|"([^"]|\\")*")*$
      datepattern = LongEpoch
    '';
  };
}
