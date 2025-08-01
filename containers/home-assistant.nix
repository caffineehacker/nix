{ config, lib, ... }:
let
  cfg = config.tw.containers.home-assistant;
  helpers = import ./helpers.nix { inherit lib; };
in
{
  imports = [ (helpers.module cfg) ];

  config = lib.mkIf cfg.enable {
    containers."${cfg.name}".config = { ... }: {
      imports = [ (helpers.containerConfigModule cfg) ];

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
}
