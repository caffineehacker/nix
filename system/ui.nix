{ lib
, pkgs
, config
, inputs
, ...
}:
let
  cfg = config.tw.system.ui;
in
{
  options = {
    tw.system.ui.enable = lib.mkOption {
      default = config.services.xserver.enable || config.tw.programs.hyprland.enable;
      example = true;
      description = ''
        Enable UI setup such as a greeter.
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.regreet = {
      enable = true;
      settings = {
        background = {
          path =
            let
              inherit (inputs.nix-colors.lib.contrib { inherit pkgs; })
                nixWallpaperFromScheme;
              wallpaper = nixWallpaperFromScheme {
                scheme = config.tw.users.tim.colorScheme;
                width = 2560;
                height = 1600;
                logoScale = 5.0;
              };
            in
            wallpaper;
        };
        "widget.clock" = {
          # Shows "Sunday June 1 - 1:04 PM"
          format = "%A %B %-d - %-I:%M %P";
        };
      };
    };
  };
}
