{ lib
, config
, ...
}: {
  home-manager = lib.mkIf config.tw.programs.hyprland.enable {
    users.tim = {
      programs.wofi = {
        enable = true;
        settings = {
          width = 600;
          height = 300;
          location = "center";
          show = "drun";
          prompt = "Search...";
          filter_rate = 100;
          allow_markup = true;
          no_actions = true;
          halign = "fill";
          orientation = "vertical";
          content_haligh = "fill";
          insensitive = true;
          allow_images = true;
          image_size = 40;
          gtk_dark = true;
          dynamic_lines = true;
        };
        style = builtins.readFile ./hyprv4/wofi/style/v4-style-dark.css;
      };
    };
  };
}
