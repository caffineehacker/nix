{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.tw.programs.hyprland;
in {
  options = {
    tw.programs.hyprland.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable hyprland
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;
  };
}