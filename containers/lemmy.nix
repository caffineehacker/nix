{config, lib, ...}: let
  cfg = config.tw.containers.lemmy;
  tunnelFile = config.sops.secrets."cloudflare/tunnels/lemmy.json".path;
in {
  options = {
    tw.containers.lemmy.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable lemmy container
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    containers.lemmy = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.10";
      localAddress = "10.0.0.110";

      extraFlags = [
        # Load the cloudflare secret
        "--load-credential=tunnel.json:${tunnelFile}"
      ];

      config = {config, pkgs, lib, ...}: {
        system.stateVersion = "23.11";

        imports = [
          ./cloudflared.nix
        ];

        services.lemmy = {
          enable = true;
          settings = {
            hostname = "lemmy.timwaterhouse.com";
          };
          database = {
            createLocally = true;
          };
        };

        tw.containers.cloudflared = {
          tunnelId = "7abb4240-e222-48ae-a335-5557b3fe6b9c";
          hostname = "lemmy.timwaterhouse.com";
          port = 8180;
        };

        services.caddy = {
          enable = true;
          globalConfig = ''
            auto_https off
            http_port  8180
            https_port 8181
          '';
          virtualHosts.":8180" = {
            extraConfig = ''
              handle_path /static/* {
                root * ${config.services.lemmy.ui.package}/dist
                file_server
              }
              handle_path /static/${config.services.lemmy.ui.package.passthru.commit_sha}/* {
                root * ${config.services.lemmy.ui.package}/dist
                file_server
              }
              @for_backend {
                path /api/* /pictrs/* /feeds/* /nodeinfo/*
              }
              handle @for_backend {
                reverse_proxy 127.0.0.1:${toString config.services.lemmy.settings.port}
              }
              @post {
                method POST
              }
              handle @post {
                reverse_proxy 127.0.0.1:${toString config.services.lemmy.settings.port}
              }
              @jsonld {
                header Accept "application/activity+json"
                header Accept "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""
              }
              handle @jsonld {
                reverse_proxy 127.0.0.1:${toString config.services.lemmy.settings.port}
              }
              handle {
                reverse_proxy 127.0.0.1:${toString config.services.lemmy.ui.port}
              }
            '';
          };
        };

        services.fail2ban = {
          enable = true;
          # Ban IP after 5 failures
          maxretry = 5;
          bantime = "1h";
          bantime-increment = {
            # Enable increment of bantime after each violation
            enable = true;
            multipliers = "1 2 4 8 16 32 64";
            # Do not ban for more than 1 week
            maxtime = "168h";
            # Calculate the bantime based on all the violations
            overalljails = true;
          };
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
            failregex = ^([^"]|"([^"]|\\")*")*"Cf-Connecting-Ip":\["<ADDR>"\]([^"]|"([^"]|\\")*")*"status":(0|403|404)([^"]|"([^"]|\\")*")*$
            datepattern = LongEpoch
          '';
        };

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [ ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.resolved.enable = true;
      };
    };
  };
}