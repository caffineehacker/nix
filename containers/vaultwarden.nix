{config, lib, ...}: let
  cfg = config.tw.containers.vaultwarden;
  tunnelFile = config.sops.secrets."cloudflare/tunnels/vaultwarden.json".path;
in {
  options = {
    tw.containers.vaultwarden.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable Vaultwarden container
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    containers.vaultwarden = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.20";
      localAddress = "10.0.0.120";

      extraFlags = [
        # Load the cloudflare secret
        "--load-credential=tunnel.json:${tunnelFile}"
      ];

      config = {config, pkgs, lib, ...}: {
        system.stateVersion = "23.11";

        imports = [
          ./cloudflared.nix
        ];

        services.vaultwarden = {
          enable = true;
          backupDir = "/var/backup/vaultwarden";
          config = {
            DOMAIN = "https://vault.timwaterhouse.com";
            SIGNUPS_ALLOWED = false;
            SIGNUPS_VERIFY = true;
            INVITATION_ORG_NAME = "Vaultwarden";
            IP_HEADER = "X-Forwarded-For";
            ROCKET_ADDRESS = "127.0.0.1";
            ROCKET_PORT = 8222;
            # TODO: Enable email sending!
          };
        };

        tw.containers.cloudflared = {
          tunnelId = "f84a6d56-e3a7-41eb-96fa-71afb3cf090a";
          hostname = "vault.timwaterhouse.com";
          port = 8222;
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

        environment.etc = {
          "fail2ban/filter.d/vaultwarden.local".text = ''
            [Definition]
            failregex = ^.*?Username or password is incorrect\. Try again\. IP: <ADDR>\. Username:.*$
            backend = systemd
            journalmatch = _SYSTEMD_UNIT=vaultwarden.service
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
            vaultwarden.settings = {
              enabled = true;
              filter = "vaultwarden";
              backend = "systemd";
            };
          };
        };
      };
    };
  };
}