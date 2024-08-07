{ lib
, config
, ...
}:
let
  cfg = config.tw.users.tim.wlogout;
  cfgWlogout = config.home-manager.users.tim.programs.wlogout;
in
{
  options = {
    tw.users.tim.wlogout.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable wlogout
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users.tim = {
        programs.wlogout.enable = true;
        programs.wlogout.layout = [
          {
            label = "lock";
            action = "swaylock && sleep 1 && hyprctl dispatch dpms off";
            text = "Lock";
          }
          {
            label = "hibernate";
            action = "systemctl hibernate";
            text = "Hibernate";
          }
          {
            label = "logout";
            action = "hyprctl dispatch exit";
            text = "Logout";
          }
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
          }
          {
            label = "suspend";
            action = "systemctl suspend";
            text = "Suspend";
          }
          {
            label = "reboot";
            action = "systemctl reboot";
            text = "Reboot";
          }
        ];
        programs.wlogout.style = ''
          * {
            font-family: monospace;
            font-size: 15px;
            font-weight: bold;
          }

          window {
            background-color: #${config.tw.users.tim.colorScheme.palette.base00};
            opacity: 0.9;
          }

          button {
            background-size: 20%;
            border: 2px solid #${config.tw.users.tim.colorScheme.palette.base08};
            border-radius: 3rem;
            background-color: #${config.tw.users.tim.colorScheme.palette.base01};
            margin: 10px;
            color: #${config.tw.users.tim.colorScheme.palette.base05};
          }

          button:hover,
          button:focus {
            background-color: #${config.tw.users.tim.colorScheme.palette.base05};
            color: #${config.tw.users.tim.colorScheme.palette.base01};
          }

          #lock {
              background-image: image(url("${cfgWlogout.package}/share/wlogout/icons/lock.png"), url("${cfgWlogout.package}/local/share/wlogout/icons/lock.png"));
          }

          #logout {
              background-image: image(url("${cfgWlogout.package}/share/wlogout/icons/logout.png"), url("${cfgWlogout.package}/local/share/wlogout/icons/logout.png"));
          }

          #suspend {
              background-image: image(url("${cfgWlogout.package}/share/wlogout/icons/suspend.png"), url("${cfgWlogout.package}/local/share/wlogout/icons/suspend.png"));
          }

          #hibernate {
              background-image: image(url("${cfgWlogout.package}/share/wlogout/icons/hibernate.png"), url("${cfgWlogout.package}/local/share/wlogout/icons/hibernate.png"));
          }

          #shutdown {
              background-image: image(url("${cfgWlogout.package}/share/wlogout/icons/shutdown.png"), url("${cfgWlogout.package}/local/share/wlogout/icons/shutdown.png"));
          }

          #reboot {
              background-image: image(url("${cfgWlogout.package}/share/wlogout/icons/reboot.png"), url("${cfgWlogout.package}/local/share/wlogout/icons/reboot.png"));
          }
        '';
      };
    };
  };
}
