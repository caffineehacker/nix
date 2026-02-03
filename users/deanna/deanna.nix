{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.tw.users.deanna;
in
{
  options = {
    tw.users.deanna.enable = lib.mkOption {
      default = true;
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

        home.packages = with pkgs; [
          firefox
        ];

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

    services.desktopManager.plasma6.enable = true;
    # Kde and Gnome conflict with this setting
    programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";
  };
}
