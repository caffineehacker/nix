{ config, lib, ... }:
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
          extraComponents = [
            # Components required to complete the onboarding
            "esphome"
            "met"
            "radio_browser"
            "zwave_me"
            "zwave_js"
          ];
          config = {
            # Includes dependencies for a basic setup
            # https://www.home-assistant.io/integrations/default_config/
            default_config = { };
            http = {
              server_host = "::1";
              trusted_proxies = [ "::1" ];
              use_x_forwarded_for = true;
            };
          };
        };
      };
    };
  };
}
