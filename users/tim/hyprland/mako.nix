{ lib
, config
, ...
}: {
  home-manager = lib.mkIf config.tw.programs.hyprland.enable {
    users.tim = {
      services.mako = {
        enable = true;

        maxVisible = 5;
        layer = "overlay";
        anchor = "center";
        font = "Fantasque Sans Mono 14";
        width = 300;
        height = 100;
        margin = "10";
        padding = "15";
        borderSize = 2;
        borderRadius = 10;

        backgroundColor = "#" + config.tw.users.tim.colorScheme.palette.base00;
        textColor = "#" + config.tw.users.tim.colorScheme.palette.base05;
        borderColor = "#" + config.tw.users.tim.colorScheme.palette.base01;
        progressColor = "over #${config.tw.users.tim.colorScheme.palette.base06}";

        icons = true;
        maxIconSize = 48;
        markup = true;
        actions = true;
        defaultTimeout = 5000;
        ignoreTimeout = false;

        extraConfig = ''
          [urgency=low]
          default-timeout=2000

          [urgency=normal]
          default-timeout=5000

          [urgency=high]
          default-timeout=0
        '';
      };
    };
  };
}
