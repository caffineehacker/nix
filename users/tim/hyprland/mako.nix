{ lib
, config
, ...
}: {
  home-manager = lib.mkIf config.tw.programs.hyprland.enable {
    users.tim = {
      services.mako = {
        enable = true;

        settings =
          {
            maxVisible = 5;
            layer = "overlay";
            anchor = "center";
            font = "Fantasque Sans Mono 14";
            width = 300;
            height = 100;
            margin = "10";
            padding = "15";
            border-size = 2;
            border-radius = 10;

            background-color = "#" + config.tw.users.tim.colorScheme.palette.base00;
            text-color = "#" + config.tw.users.tim.colorScheme.palette.base05;
            border-color = "#" + config.tw.users.tim.colorScheme.palette.base01;
            progress-color = "over #${config.tw.users.tim.colorScheme.palette.base06}";

            icons = true;
            max-icon-size = 48;
            markup = true;
            actions = true;
            default-timeout = 5000;
            ignore-timeout = false;

            "urgency=low" = {
              default-timeout = 2000;
            };
            "urgency=normal" = {
              default-timeout = 5000;
            };
            "urgency=high" = {
              default-timeout = 0;
            };
          };
      };
    };
  };
}


