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
            max-visible = 5;
            layer = "overlay";
            anchor = "center";
            width = 300;
            height = 100;
            margin = "10";
            padding = "15";
            border-size = 2;
            border-radius = 10;

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


