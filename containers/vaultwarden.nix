{ config, lib, ... }:
let
  cfg = config.tw.containers.vaultwarden;
  helpers = import ./helpers.nix { inherit lib; };
in
{
  imports = [ (helpers.module cfg) ];

  config = lib.mkIf cfg.enable {
    containers."${cfg.name}".config = { ... }: {
      imports = [ (helpers.containerConfigModule cfg) ];

      services.vaultwarden = {
        enable = true;
        backupDir = "/var/backup/vaultwarden";
        config = {
          DOMAIN = "https://${cfg.hostname}";
          SIGNUPS_ALLOWED = false;
          SIGNUPS_VERIFY = true;
          INVITATION_ORG_NAME = "Vaultwarden";
          IP_HEADER = "X-Forwarded-For";
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = cfg.cloudflare.port;
          # TODO: Enable email sending!
        };
      };

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
}
