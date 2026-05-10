{ lib
, config
, ...
}:
let
  cfg = config.tw.users.deanna;
in
{
  options = {
    tw.users.deanna.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable user deanna
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    tw.users.home-manager.enable = true;

    home-manager = {
      users.deanna = {
        home.username = "deanna";
        home.homeDirectory = "/home/deanna";
        home.stateVersion = "23.05";

        programs.home-manager.enable = true;
      };
    };

    users.users.deanna = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "input"
      ];
    };

    stylix.autoEnable = false;
  };
}
