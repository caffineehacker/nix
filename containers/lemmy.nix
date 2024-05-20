{config, lib, ...}: let
  cfg = config.tw.containers.lemmy;
  tunnelFile = config.sops.secrets."cloudflare/tunnels/homelab.json".path;
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
        "--load-credential=homelab.json:${tunnelFile}"
      ];

      config = {config, pkgs, lib, ...}: {
        system.stateVersion = "23.11";
        services.lemmy = {
          enable = true;
          settings = {
            hostname = "lemmy.timwaterhouse.com";
          };
          database = {
            createLocally = true;
          };
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
            allowedTCPPorts = [ 8180 8181 ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.resolved.enable = true;

        services.cloudflared = {
          enable = true;
          tunnels = {
            "389d646c-ea05-4a8c-80b0-ffa2483a0b33" = {
              credentialsFile = "@CREDENTIALS_FILE@";
              ingress = {
                "lemmy.timwaterhouse.com" = "http://localhost:8180";
              };
              default = "http_status:404";
            };
          };
        };

        systemd.services."cloudflared-tunnel-389d646c-ea05-4a8c-80b0-ffa2483a0b33" = 
          let
            filterConfig = lib.attrsets.filterAttrsRecursive (_: v: ! builtins.elem v [ null [ ] { } ]);

            fullConfig = filterConfig {
              tunnel = "389d646c-ea05-4a8c-80b0-ffa2483a0b33";
              "credentials-file" = "@CREDENTIALS_FILE@";
              ingress = [
                {
                  hostname = "lemmy.timwaterhouse.com";
                  service = "http://localhost:8180";
                }
                { service = "http_status:404"; }
              ];
            };

            mkConfigFile = pkgs.writeText "cloudflared.yml" (builtins.toJSON fullConfig);
          in
          {
            serviceConfig.LoadCredential = [
              "homelab.json"
            ];
            serviceConfig.RuntimeDirectory = "cloudflared-tunnel-389d646c-ea05-4a8c-80b0-ffa2483a0b33";
            preStart = ''
              install -m600 ${mkConfigFile} $RUNTIME_DIRECTORY/cloudflared.yml
              ${pkgs.gnused}/bin/sed -i "s;@CREDENTIALS_FILE@;$CREDENTIALS_DIRECTORY/homelab.json;g" $RUNTIME_DIRECTORY/cloudflared.yml
            '';
            serviceConfig.ExecStart = lib.mkForce "${pkgs.bash}/bin/bash -c '${pkgs.cloudflared}/bin/cloudflared tunnel --config=$RUNTIME_DIRECTORY/cloudflared.yml --no-autoupdate run'";
          };
      };
    };
  };
}