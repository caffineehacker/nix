{...}:
{
  services.cloudflared = {
    enable = true;
    user = "tim";
    tunnels = {
      "[TUNNEL ID]" = {
        credentialsFile = "${config.users.users.[HOME USER NAME].home}/.cloudflared/[TUNNEL ID].json";
        default = "http_status:404";
      };
    };
  };
}