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