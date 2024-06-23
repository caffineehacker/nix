{config, ...}:
let
  tunnelFile = config.sops.secrets."cloudflare/tunnels/homelab.json".path;
in {
  sops.secrets."cloudflare/tunnels/homelab.json" = {
    owner = config.services.cloudflared.user;
    inherit (config.services.cloudflared) group;
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "389d646c-ea05-4a8c-80b0-ffa2483a0b33" = {
        credentialsFile = tunnelFile;
        ingress = {
          "homelab.timwaterhouse.com" = "ssh://localhost:22";
        };
        default = "http_status:404";
      };
    };
  };
}