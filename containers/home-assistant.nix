{ config, lib, pkgs, ... }:
let
  cfg = config.tw.containers.home-assistant;
  helpers = import ./helpers.nix { inherit lib; };
in
{
  imports = [ (helpers.module cfg) ];

  config = lib.mkIf cfg.enable {
    containers."${cfg.name}" = {
      allowedDevices = [
        {
          node = "/dev/ttyACM0";
          modifier = "rwm";
        }
      ];
      bindMounts."/dev/ttyACM0" = { hostPath = "/dev/ttyACM0"; isReadOnly = false; };
      config = { ... }: {
        imports = [ (helpers.containerConfigModule cfg) ];

        systemd.services.chmodDevTty = {
          serviceConfig = {
            Type = "oneshot";
          };
          wantedBy = [ "zwave-js.service" ];
          script = ''
            chmod a+rw /dev/ttyACM0
          '';
        };

        system.activationScripts.changeTtyMods = {
          text = ''
            chmod a+rw /dev/ttyACM0
          '';
        };

        networking.firewall.allowedTCPPorts = [ 8091 ];

        services.zwave-js = {
          enable = true;
          serialPort = "/dev/ttyACM0";
          # This needs to be manually created in the container
          secretsConfigFile = "/etc/zwave_secrets";
        };

        services.zwave-js-ui = {
          enable = true;
          serialPort = "/dev/ttyACM0";
          settings = {
            HOST = "::1";
            PORT = "8091";
          };
        };

        services.home-assistant = {
          enable = true;
          package = (pkgs.home-assistant.override {
            extraComponents = [
              # Components required to complete the onboarding
              "esphome"
              "met"
              "mqtt"
              "radio_browser"
              "zwave_me"
              "zwave_js"
            ];
          });
          # Temporarily use local config until I have everything working...
          configDir = "/etc/home-assistant";
          config = null;
          # config = {
          #   # Includes dependencies for a basic setup
          #   # https://www.home-assistant.io/integrations/default_config/
          #   default_config = { };
          #   http = {
          #     server_host = "::1";
          #     trusted_proxies = [ "::1" ];
          #     use_x_forwarded_for = true;
          #   };
          # };
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
          jails = {
            home-assistant = {
              settings = {
                enabled = true;
                filter = "home-assistant";
              };
            };
          };
        };
        # This regex ignores all json and ensures we're not in a string when we find the remote_ip and status fields
        environment.etc."fail2ban/filter.d/home-assistant.local" = {
          text = ''
            [Definition]
            failregex = ^.* \[homeassistant\.components\.http\.ban\] Login attempt or request with invalid authentication from <HOST>.*$
            ignoreregex =
            journalmatch = _SYSTEMD_UNIT=home-assistant.service + _COMM=home-assistant
            datepattern = {^LN-BEG}
          '';
        };
      };
    };
  };
}
