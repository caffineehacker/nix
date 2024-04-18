{ lib
, config
, ...
}:
let
  # This is taken from Home Manager's wofi.nix
  toConfig = attrs:
  ''
    # Generated by Home Manager.
  '' + lib.generators.toKeyValue { }
  (lib.filterAttrs (name: value: value != null) attrs);
 in {
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

      xdg.configFile."wofi/config-bmenu".text = toConfig {
        width = 375;
        height = -450;
        location = "top_left";
        show = "drun";
        prompt = "Search...";
        filter_rate = 100;
        allow_markup = true;
        no_actions = false;
        halign = "fill";
        orientation = "vertical";
        content_halign = "fill";
        insensitive = true;
        allow_images = true;
        image_size = 32;
        gtk_dark = true;
        layer = "top";
      };
    };
  };
}
