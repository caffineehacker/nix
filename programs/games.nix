{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.games;
in {
  options = {
    programs.games.enable = lib.mkOption {
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
  };
}