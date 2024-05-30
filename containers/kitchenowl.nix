{config, lib, ...}: let
  cfg = config.tw.containers.kitchenowl;
  tunnelFile = config.sops.secrets."cloudflare/tunnels/kitchenowl.json".path;
in {
  options = {
    tw.containers.kitchenowl.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable Kitchenowl container
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    containers.kitchenowl = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.12";
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

        services.kitchenowl = {
          enable = true;
          settings = {
            hostname = "kitchen.timwaterhouse.com";
          };
          database = {
            createLocally = true;
          };
        };

        tw.containers.cloudflared = {
          tunnelId = "7abb4240-e222-48ae-a335-5557b3fe6b9c";
          hostname = "kitchen.timwaterhouse.com";
          port = 8180;
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