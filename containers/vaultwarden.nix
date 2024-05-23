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
      };
    };
  };
}