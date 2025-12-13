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

        # NOTE: MQTT and z-wave JS need to be manually configured in the home assistant
        # UI for some reason. They cannot be configured declaritively :-(
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
          configDir = "/var/lib/haas";
          config = {
            default_config = { };
            automation = "!include automations.yaml";
            mqtt = {
              climate =
                let
                  heatPump = name: baseTopic: {
                    inherit name;
                    device = {
                      name = "${name} Heatpump";
                      identifiers = [
                        baseTopic
                      ];
                    };
                    unique_id = "${baseTopic}";
                    optimistic = true;
                    current_temperature_topic = "${baseTopic}/status";
                    current_temperature_template = "{{ value_json.roomTemperature }}";
                    mode_state_topic = "${baseTopic}";
                    mode_command_topic = "${baseTopic}/set";
                    swing_horizontal_mode_state_topic = "${baseTopic}";
                    swing_mode_state_topic = "${baseTopic}";
                    temperature_state_topic = "${baseTopic}";
                    temperature_command_topic = "${baseTopic}/set";
                    fan_mode_state_topic = "${baseTopic}/status";
                    fan_mode_command_topic = "${baseTopic}/set";
                    fan_mode_command_template = "{{ {'fan': value}|to_json }}";
                    fan_mode_state_template = "{{ value_json.fan }}";
                    fan_modes = [
                      "AUTO"
                      "QUIET"
                      "1"
                      "2"
                      "3"
                      "4"
                    ];
                    min_temp = 61.0;
                    mode_state_template = "{% if value_json.power == 'OFF' %}{{ 'off' }}{% else %}{{ { 'COOL': 'cool', 'HEAT': 'heat', 'DRY': 'dry', 'FAN': 'fan_only', 'AUTO': 'auto' }[value_json.mode] }}{% endif %}";
                    mode_command_template = "{% if value == 'off' %} {{ {'power': 'OFF'}|to_json }} {% else %} {{ {'power': 'ON', 'mode': { 'cool': 'COOL', 'heat': 'HEAT', 'dry': 'DRY', 'fan_only': 'FAN', 'auto': 'AUTO' }[value] }|to_json }} {% endif %}";
                    swing_horizontal_mode_state_template = "{{ value_json.wideVane }}";
                    swing_horizontal_modes = [
                      "<<"
                      "<"
                      "|"
                      ">"
                      ">>"
                      "<>"
                      "SWING"
                    ];
                    swing_mode_state_template = "{{ value_json.vane }}";
                    swing_modes = [
                      "AUTO"
                      "1"
                      "2"
                      "3"
                      "4"
                      "5"
                      "SWING"
                    ];
                    temperature_state_template = "{{ value_json.temperature }}";
                    temperature_unit = "F";
                    temperature_command_template = "{{ {'temperature': value}|to_json }}";
                  };
                in
                [
                  (heatPump "Tim's Office" "heatpump/timsoffice")
                  (heatPump "Dining Room" "heatpump/hpdiningroom")
                  (heatPump "Outdoor Office" "heatpump/outdooroffice")
                  (heatPump "Family Room" "heatpump/familyroom")
                  (heatPump "Bedroom" "heatpump/hpmasterbdrm")
                  (heatPump "Connor's Room" "heatpump/hpconnorsroom")
                ];
            };
            homeassistant = { };
            http = {
              server_host = "::1";
              server_port = cfg.cloudflare.port;
              trusted_proxies = [ "::1" ];
              use_x_forwarded_for = true;
              ip_ban_enabled = true;
              login_attempts_threshold = 5;
            };
            lovelace = {
              mode = "storage";
              resources = [ ];
            };
          };
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

