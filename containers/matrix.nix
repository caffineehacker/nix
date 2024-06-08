{config, lib, ...}: let
  cfg = config.tw.containers.matrix;
  tunnelFile = config.sops.secrets."cloudflare/tunnels/matrix.json".path;
  matrixSharedSecretFile = config.sops.secrets."matrix/sharedSecret".path;
  wireguardPrivateKeyFile = config.sops.secrets."matrix/wireguard/clientKey".path;
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
        # This is a special name to automatically load this secret as the private key
        "--load-credential=network.wireguard.private.10-wg0:${wireguardPrivateKeyFile}"
      ];

      config = {config, pkgs, lib, ...}: {
        system.stateVersion = "23.11";

        imports = [
          ./cloudflared.nix
          ../programs/systemd.nix
        ];

        tw.programs.systemd.nextVersion.enable = true;

        boot.extraModulePackages = [config.boot.kernelPackages.wireguard];
        systemd.network = {
          enable = true;
          netdevs = {
            "10-wg0" = {
              netdevConfig = {
                Kind = "wireguard";
                Name = "wg0";
                MTUBytes = "1300";
              };
              wireguardConfig = {
              };
              wireguardPeers = [
              {
                PublicKey = "ecv9aiMiBB4FymTEjN+VMMAYJVaFUvUkBUTp8CIfhRo=";
                AllowedIPs = ["10.100.0.1"];
                Endpoint = "129.153.214.198:51820";
                PersistentKeepalive = 5;
              }
            ];
            };
          };
          networks.wg0 = {
            matchConfig.Name = "wg0";
            address = [
              "10.100.0.2/24"
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

        environment.etc = {
          "fail2ban/filter.d/matrix.local".text = ''
            [Definition]
            failregex = ^matrix synapse\[\d+\]: synapse.access.http.\d+: \[(POST|GET)\-\d+\] <ADDR> - \d+ - .* <F-ERRCODE>403</F-ERRCODE> "(POST|GET) .*$
            backend = systemd
            journalmatch = _SYSTEMD_UNIT=matrix-synapse.service
          '';
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
          ignoreIP = [
            "10.0.0.0/24"
            "10.100.0.0/24"
          ];
          jails = {
            matrix.settings = {
              enabled = true;
              filter = "matrix";
              backend = "systemd";
            };
          };
        };

        environment.systemPackages = with pkgs; [ wireguard-tools ];

        services.matrix-synapse = {
          enable = true;
          settings = {
            server_name = "matrix.timwaterhouse.com";
            public_baseurl = "https://matrix.timwaterhouse.com";
            listeners = [
              { port = 8008;
                bind_addresses = [ "::1" "10.100.0.2" "10.0.0.141" ];
                type = "http";
                tls = false;
                x_forwarded = true;
                resources = [ {
                  names = [ "client" "federation" ];
                  compress = true;
                } ];
              }
            ];
            modules = [
              {
                module = "mjolnir.Module";
                config = {
                  block_invites = true;
                  block_messages = true;
                  block_usernames = true;
                  ban_lists = [
                    "!matrix-org-coc-bl:matrix.org"
                    "!matrix-org-hs-tos-bl:matrix.org"
                  ];
                };
              }
            ];
          };
          extraConfigFiles = [
            "${config.services.matrix-synapse.dataDir}/matrix-shared-secret"
          ];
          plugins = with pkgs; [
            matrix-synapse-plugins.matrix-synapse-mjolnir-antispam
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
            allowedTCPPorts = [ 8008 ];
            allowedUDPPorts = [ 8008 ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };

        services.resolved.enable = true;

        # # enable coturn
        # services.coturn = rec {
        #   enable = true;
        #   no-cli = true;
        #   no-tcp-relay = true;
        #   min-port = 49000;
        #   max-port = 50000;
        #   use-auth-secret = true;
        #   static-auth-secret = "will be world readable for local users :(";
        #   realm = "turn.example.com";
        #   cert = "${config.security.acme.certs.${realm}.directory}/full.pem";
        #   pkey = "${config.security.acme.certs.${realm}.directory}/key.pem";
        #   extraConfig = ''
        #     # for debugging
        #     verbose
        #     # ban private IP ranges
        #     no-multicast-peers
        #     denied-peer-ip=0.0.0.0-0.255.255.255
        #     denied-peer-ip=10.0.0.0-10.255.255.255
        #     denied-peer-ip=100.64.0.0-100.127.255.255
        #     denied-peer-ip=127.0.0.0-127.255.255.255
        #     denied-peer-ip=169.254.0.0-169.254.255.255
        #     denied-peer-ip=172.16.0.0-172.31.255.255
        #     denied-peer-ip=192.0.0.0-192.0.0.255
        #     denied-peer-ip=192.0.2.0-192.0.2.255
        #     denied-peer-ip=192.88.99.0-192.88.99.255
        #     denied-peer-ip=192.168.0.0-192.168.255.255
        #     denied-peer-ip=198.18.0.0-198.19.255.255
        #     denied-peer-ip=198.51.100.0-198.51.100.255
        #     denied-peer-ip=203.0.113.0-203.0.113.255
        #     denied-peer-ip=240.0.0.0-255.255.255.255
        #     denied-peer-ip=::1
        #     denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
        #     denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
        #     denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
        #     denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
        #     denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        #     denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        #     denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        #   '';
        # };
        # # open the firewall
        # networking.firewall = {
        #   interfaces.enp2s0 = let
        #     range = with config.services.coturn; [ {
        #     from = min-port;
        #     to = max-port;
        #   } ];
        #   in
        #   {
        #     allowedUDPPortRanges = range;
        #     allowedUDPPorts = [ 3478 5349 ];
        #     allowedTCPPortRanges = [ ];
        #     allowedTCPPorts = [ 3478 5349 ];
        #   };
        # };
        # # get a certificate
        # security.acme.certs.${config.services.coturn.realm} = {
        #   /* insert here the right configuration to obtain a certificate */
        #   postRun = "systemctl restart coturn.service";
        #   group = "turnserver";
        # };
        # # configure synapse to point users to coturn
        # services.matrix-synapse = with config.services.coturn; {
        #   turn_uris = ["turn:${realm}:3478?transport=udp" "turn:${realm}:3478?transport=tcp"];
        #   turn_shared_secret = static-auth-secret;
        #   turn_user_lifetime = "1h";
        # };
      };
    };
  };
}