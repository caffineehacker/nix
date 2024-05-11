{ lib
, config
, ...
}:
let
  cfg = config.tw.services.ssh;
in
{
  options = {
    tw.services.kdeconnect.enable = lib.mkOption {
      default = true;
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