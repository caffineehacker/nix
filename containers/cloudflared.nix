## Create a tunnel with:
## `cloudflared tunnel login`
## `cloudflared tunnel create <name>`
## `cat ~/.cloudflared/<tunnel_id>.json`
## `sops secrets/secrets.yaml` and add paste the above json in single quotes to a key
## `cloudflared tunnel route dns <name> <hostname>`
{ pkgs, lib, config, ... }:
let
  cfg = config.tw.containers.cloudflared;
in
{
  options = {
    tw.containers.cloudflared.tunnelId = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "389d646c-ea05-4a8c-80b0-ffa2483a0b33";
      description = "The tunnel ID";
    };

    tw.containers.cloudflared.hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "my_container.timwaterhouse.com";
      description = "The container FQDN hostname";
    };

    tw.containers.cloudflared.port = lib.mkOption {
      type = lib.types.int;
      default = null;
      example = "8080";
      description = "The service port number";
    };
  };

  config = {
    services.cloudflared = {
      enable = true;
      tunnels = {
        "${cfg.tunnelId}" = {
          credentialsFile = "/nonsense";
          ingress = {
            "${cfg.hostname}" = "http://localhost:${builtins.toString cfg.port}";
          };
          default = "http_status:404";
        };
      };
    };

    systemd.services."cloudflared-tunnel-${cfg.tunnelId}" =
      let
        filterConfig = lib.attrsets.filterAttrsRecursive (_: v: ! builtins.elem v [ null [ ] { } ]);

        fullConfig = filterConfig {
          tunnel = "${cfg.tunnelId}";
          "credentials-file" = "/run/credentials/cloudflared-tunnel-${cfg.tunnelId}.service/tunnel.json";
          ingress = [
            {
              hostname = "${cfg.hostname}";
              service = "http://localhost:${builtins.toString cfg.port}";
            }
            { service = "http_status:404"; }
          ];
        };

        mkConfigFile = pkgs.writeText "cloudflared.yml" (builtins.toJSON fullConfig);
      in
      {
        after = [
          "network.target"
          "network-online.target"
        ];
        wants = [
          "network.target"
          "network-online.target"
        ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          RuntimeDirectory = "cloudflared-tunnel-${cfg.tunnelId}";
          RuntimeDirectoryMode = "0400";
          LoadCredential = lib.mkForce [
            "tunnel.json"
          ];
          ExecStart = lib.mkForce "${pkgs.cloudflared}/bin/cloudflared tunnel --config=${mkConfigFile} --no-autoupdate run";
          Restart = "on-failure";
          DynamicUser = true;
        };
      };
  };
}
