{ lib
, config
, ...
}:
let
  cfg = config.tw.services.kdeconnect;
in
{
  options = {
    tw.services.kdeconnect.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable the KDE connect
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.kdeconnect.enable = true;
  };
}
