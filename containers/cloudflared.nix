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
          credentialsFile = "@CREDENTIALS_FILE@";
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
          "credentials-file" = "@CREDENTIALS_FILE@";
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
        serviceConfig = {
          LoadCredential = [
            "tunnel.json"
          ];
          RuntimeDirectory = "cloudflared-tunnel-${cfg.tunnelId}";
          ExecStart = lib.mkForce "${pkgs.bash}/bin/bash -c '${pkgs.cloudflared}/bin/cloudflared tunnel --config=$RUNTIME_DIRECTORY/cloudflared.yml --no-autoupdate run'";
        };
        preStart = ''
          install -m600 ${mkConfigFile} $RUNTIME_DIRECTORY/cloudflared.yml
          ${pkgs.gnused}/bin/sed -i "s;@CREDENTIALS_FILE@;$CREDENTIALS_DIRECTORY/tunnel.json;g" $RUNTIME_DIRECTORY/cloudflared.yml
        '';
      };
  };
}
