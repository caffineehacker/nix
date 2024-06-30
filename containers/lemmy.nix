{config, lib, ...}: let
  cfg = config.tw.containers.lemmy;
  helpers = import ./helpers.nix { inherit lib; };
in {
  imports = [ (helpers.module cfg) ];

  config = lib.mkIf cfg.enable {
    containers."${cfg.name}".config = {...}: {
      imports = [ (helpers.containerConfigModule cfg) ];
      services.lemmy = {
        enable = true;
        settings = {
          hostname = cfg.hostname;
        };
        database = {
          createLocally = true;
        };
      };

      services.caddy = {
        enable = true;
        globalConfig = ''
          auto_https off
          http_port  ${builtins.toString cfg.cloudflare.port}
          https_port ${builtins.toString (cfg.cloudflare.port + 1)}
        '';
        virtualHosts.":${builtins.toString cfg.cloudflare.port}" = {
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
    };
  };
}