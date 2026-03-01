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
        "widget.clock" = {
          # Shows "Sunday June 1 - 1:04 PM"
          format = "%A %B %-d - %-I:%M %P";
        };
      };
      # Make cage use the last monitor instead of spanning both monitors
      cageArgs = [ "-m" "last" ];
    };
  };
}
