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

        networking.firewall.allowedTCPPorts = [ 8091 cfg.wireguard.port ];

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
              "esphome"
              "met"
              "mqtt"
              "radio_browser"
              "zwave_me"
              "zwave_js"
              "govee_light_local"
            ];
          });
          configDir = "/var/lib/haas";
          config = {
            default_config = { };
            "automation ui" = "!include automations.yaml";
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
                    default_entity_id = "climate." + (lib.strings.removePrefix "heatpump/" baseTopic);
                    optimistic = true;
                    current_temperature_topic = "${baseTopic}/status";
                    current_temperature_template = "{{ value_json.roomTemperature }}";
                    mode_state_topic = "${baseTopic}";
                    mode_command_topic = "${baseTopic}/set";
                    swing_horizontal_mode_state_topic = "${baseTopic}";
                    swing_mode_state_topic = "${baseTopic}";
                    temperature_state_topic = "${baseTopic}";
                    temperature_command_topic = "${baseTopic}/set";
                    fan_mode_command_topic = "${baseTopic}/set";
                    fan_mode_command_template = "{{ {'fan': value}|to_json }}";
                    fan_mode_state_topic = "${baseTopic}";
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
            "automation nix" =
              let
                heatPumpWithDisabledAtTime = name: baseTopic: time:
                  let
                    entityId = "climate." + (lib.strings.removePrefix "heatpump/" baseTopic);
                  in
                  [
                    {
                      alias = "${name} Heat Down";
                      description = "";
                      triggers = [
                        {
                          trigger = "time";
                          at = time;
                        }
                      ];
                      conditions = [
                        {
                          condition = "state";
                          entity_id = entityId;
                          state = "heat";
                        }
                      ];
                      actions = [
                        {
                          action = "climate.set_temperature";
                          target = {
                            entity_id = entityId;
                          };
                          data = {
                            temperature = 61;
                          };
                        }
                      ];
                    }
                    {
                      alias = "${name} A/C Off";
                      description = "";
                      triggers = [
                        {
                          trigger = "time";
                          at = "22:00:00";
                        }
                      ];
                      conditions = [
                        {
                          condition = "state";
                          entity_id = entityId;
                          state = "cool";
                        }
                      ];
                      actions = [
                        {
                          action = "climate.set_hvac_mode";
                          target = {
                            entity_id = entityId;
                          };
                          data = {
                            hvac_mode = "off";
                          };
                        }
                      ];
                    }
                  ];
                heatPumpWithDisabledEvening = name: baseTopic: heatPumpWithDisabledAtTime name baseTopic "22:00:00";
              in
              lib.lists.flatten [
                (heatPumpWithDisabledEvening "Dining Room Heat Pump" "heatpump/hpdiningroom")
                (heatPumpWithDisabledEvening "Family Room" "heatpump/familyroom")
                (heatPumpWithDisabledAtTime "Tim's Office" "heatpump/timsoffice" "17:00:00")
                (heatPumpWithDisabledAtTime "Bedroom" "heatpump/hpmasterbdrm" "07:00:00")
              ];
            homeassistant = { };
            http = {
              server_port = cfg.wireguard.port;
              trusted_proxies = [ "::1" "10.100.0.60" "10.100.0.1" ];
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
          ignoreIP = [
            "10.0.0.0/24"
            "10.100.0.0/24"
          ];
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

