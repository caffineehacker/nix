{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.tw.programs.games;
in {
  options = {
    tw.programs.games.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable to install game related programs
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.steam.enable = true;

    environment.systemPackages = with pkgs; [
      heroic
    ];
  };
}