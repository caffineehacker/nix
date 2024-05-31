{config, lib, ...}: let
  cfg = config.tw.containers.matrix;
  tunnelFile = config.sops.secrets."cloudflare/tunnels/matrix.json".path;
  matrixSharedSecretFile = config.sops.secrets."matrix/sharedSecret".path;
in {
  options = {
    tw.containers.matrix.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable Matrix Synapse container
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    containers.matrix = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.41";
      localAddress = "10.0.0.141";

      extraFlags = [
        # Load the cloudflare secret
        "--load-credential=tunnel.json:${tunnelFile}"
        "--load-credential=matrix-shared-secret:${matrixSharedSecretFile}"
      ];

      config = {config, pkgs, lib, ...}: {
        system.stateVersion = "23.11";

        imports = [
          ./cloudflared.nix
        ];

        services.matrix-synapse = {
          enable = true;
          settings = {
            server_name = "matrix.timwaterhouse.com";
            public_baseurl = "https://matrix.timwaterhouse.com";
            listeners = [
              { port = 8008;
                bind_addresses = [ "::1" ];
                type = "http";
                tls = false;
                x_forwarded = true;
                resources = [ {
                  names = [ "client" "federation" ];
                  compress = true;
                } ];
              }
            ];
          };
          extraConfigFiles = [
            "${config.services.matrix-synapse.dataDir}/matrix-shared-secret"
          ];
        };

        systemd.services.matrix-synapse = {
          serviceConfig = {
            LoadCredential = [
              "matrix-shared-secret"
            ];
          };
          preStart = ''
            install -m400 $CREDENTIALS_DIRECTORY/matrix-shared-secret ${config.services.matrix-synapse.dataDir}/matrix-shared-secret
          '';
        };

        services.postgresql.enable = true;
        services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
          CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
          CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
            TEMPLATE template0
            LC_COLLATE = "C"
            LC_CTYPE = "C";
        '';

        tw.containers.cloudflared = {
          tunnelId = "8144b7c0-1042-486a-b7b4-8d7723c8ff59";
          hostname = "matrix.timwaterhouse.com";
          port = 8008;
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