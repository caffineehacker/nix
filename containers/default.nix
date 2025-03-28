{ lib, config, ... }: {
  options =
    let
      mkContainerOptions = name: ipNumber: {
        name = lib.mkOption {
          default = name;
          example = "foo";
          description = ''
            Name of the container
          '';
          type = lib.types.str;
        };

        containerIp = lib.mkOption {
          default = "10.0.0.${builtins.toString (ipNumber + 100)}";
          example = "10.0.0.110";
          description = ''
            IP address of the network interface in the container
          '';
          type = lib.types.str;
        };
        hostIp = lib.mkOption {
          default = "10.0.0.${builtins.toString (ipNumber)}";
          example = "10.0.0.10";
          description = ''
            IP address of the container from the host
          '';
          type = lib.types.str;
        };
        hostname = lib.mkOption {
          default = "${name}.timwaterhouse.com";
          example = "example.com";
          description = ''
            Hostname of the container
          '';
          type = lib.types.str;
        };
        enable = lib.mkEnableOption name;
        cloudflare = {
          tunnelFile = lib.mkOption {
            default = config.sops.secrets."cloudflare/tunnels/${name}.json".path;
            description = ''
              Path to the file containing the private key for the cloudflare tunnel
            '';
            type = lib.types.str;
          };
          tunnelId = lib.mkOption {
            default = "";
            description = ''
              ID of the cloudflare tunnel
            '';
            type = lib.types.str;
          };
          port = lib.mkOption {
            default = 8080;
            description = ''
              Port of the container
            '';
            type = lib.types.int;
          };
        };
      };
    in
    {
      tw.containers.actual-budget = mkContainerOptions "actual-budget" 50;
      tw.containers.lemmy = mkContainerOptions "lemmy" 10;
      tw.containers.vaultwarden = mkContainerOptions "vaultwarden" 20;
      tw.containers.obsidian-sync = mkContainerOptions "obsidian-sync" 30;
      tw.containers.matrix = mkContainerOptions "matrix" 41;
    };

  config = {
    tw.containers = {
      actual-budget = {
        cloudflare = {
          tunnelId = "d87cd471-5e73-493c-8cef-ef9b3792322f";
        };
        hostname = "budget.timwaterhouse.com";
      };
      lemmy = {
        cloudflare = {
          tunnelId = "7abb4240-e222-48ae-a335-5557b3fe6b9c";
          port = 8180;
        };
      };
      vaultwarden = {
        cloudflare = {
          tunnelId = "f84a6d56-e3a7-41eb-96fa-71afb3cf090a";
          port = 8222;
        };
        hostname = "vault.timwaterhouse.com";
      };
      obsidian-sync = {
        cloudflare = {
          tunnelId = "fd12b516-c8ac-4861-bbc5-24d38659e8f0";
        };
      };
    };
  };

  imports = [
    ./actual-budget.nix
    ./lemmy.nix
    ./matrix.nix
    ./obsidian-livesync.nix
    ./vaultwarden.nix
  ];
}
