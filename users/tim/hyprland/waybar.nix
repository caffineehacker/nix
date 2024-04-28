{ lib
, config
, pkgs
, ...
}: let 
 cfgTim = config.home-manager.users.tim;
 in {
  home-manager = lib.mkIf config.tw.programs.hyprland.enable {
    users.tim = {
      programs.waybar = {
        enable = true;
        settings = {
          topBar = {
            layer = "top";
            position = "top";
            mod = "dock";
            exclusive = true;
            passthrough = false;
            gtk-layer-shell = true;
            height = 20;
            modules-left = [
              "custom/launch_wofi"
              "custom/power_btn"
              "custom/lock_screen"
              "hyprland/workspaces"
              "wlr/taskbar"
            ];
            modules-right = [
              "cpu"
              "memory"
              "disk"
              "battery"
              "pulseaudio"
              "backlight"
              "tray"
              "custom/weather"
              "power-profiles-daemon"
              "clock"
            ];

            "custom/launch_wofi" = {
              format = "";
              on-click = "pkill wofi || wofi -c ~/.config/wofi/config-bmenu";
              tooltip = false;
            };

            "custom/power_btn" = {
              format = "";
              on-click = "sh -c '(sleep 0.5s; wlogout --protocol layer-shell)' & disown";
              tooltip = false;
            };

            "custom/lock_screen" = {
              format = "";
              on-click = "sh -c '(sleep 0.5s; swaylock)' & disown";
              tooltip = false;
            };

            "hyprland/workspaces" = {
              disable-scroll = false;
              all-outputs = false;
              on-click = "activate";
              persistent-workspaces = { };
            };

            "wlr/taskbar" = {
              format = "{icon}{name}";
              icon-size = 16;
              all-outputs = false;
              tooltip-format = "{title}";
              on-click = "activate";
              on-click-middle = "close";
              ignore-list = [
                "wofi"
              ];
            };

            cpu = {
              interval = 10;
              format = " {usage}%";
              max-length = 10;
              on-click = "kitty --start-as=fullscreen --title btop sh -c 'btop'";
            };

            memory = {
              interval = 30;
              format = " {}%";
              max-length = 10;
              tooltip = true;
              tooltip-format = "Memory - {used:0.1f}GB used";
              on-click = "kitty --start-as=fullscreen --title btop sh -c 'btop'";
            };

            disk = {
              interval = 30;
              format = "󰋊 {percentage_used}%";
              path = "/";
              on-click = "kitty --start-as=fullscreen --title btop sh -c 'btop'";
            };

            battery = {
              states = {
                good = 80;
                warning = 30;
                critical = 20;
              };
              format = "{icon}";
              format-charging = " {capacity}%";
              format-plugged = " {capacity}%";
              format-alt-click = "click-right";
              format-alt = "{icon} {capacity}%";
              format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            };

            pulseaudio = {
              format = "{icon} {volume}%";
              format-muted = "";
              on-click = "${cfgTim.home.homeDirectory}/${cfgTim.xdg.configFile."hypr/scripts".target}/volume --toggle";
              on-click-right = "pavucontrol";
              on-scroll-up = "${cfgTim.home.homeDirectory}/${cfgTim.xdg.configFile."hypr/scripts".target}/volume --inc";
              on-scroll-down = "${cfgTim.home.homeDirectory}/${cfgTim.xdg.configFile."hypr/scripts".target}/volume --dec";
              scroll-step = 5;
              format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                phone = "";
                portable = "";
                car = "";
                default = [ "" "" "" ];
              };
              tooltip = true;
              tooltip-format = "{icon} at {volume}%";
            };

            "custom/weather" = {
                tooltip = true;
                format = "{}";
                interval = 30;
                exec = "~/.config/HyprV/waybar/scripts/waybar-wttr-c.py";
                return-type = "json";
            };

            power-profiles-daemon = {
              format = "{icon}";
              tooltip-format = "Power profile: {profile}";
              tooltip = true;
              format-icons = {
                default = "";
                performance = "";
                balanced = "";
                power-saver = "";
              };
            };

            clock = {
              format = " {:%I:%M %p   %m/%d/%Y}";
            };

            backlight = {
              format = "{icon} {percent}%";
              format-icons = [ "󰃞" "󰃟" "󰃠" ];
              on-scroll-up = "${cfgTim.home.homeDirectory}/${cfgTim.xdg.configFile."hypr/scripts".target}/brightness --inc";
              on-scroll-down = "${cfgTim.home.homeDirectory}/${cfgTim.xdg.configFile."hypr/scripts".target}/brightness --dec";
            };

            tray = {
              icon-size = 16;
              spacing = 10;
            };
          };
        };
        style = ''
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 16px;
    min-height: 0;
}

window#waybar {
    opacity: 1;
    background: #${config.tw.users.tim.colorScheme.palette.base00};
    color: #${config.tw.users.tim.colorScheme.palette.base05};
}

tooltip {
    background: #${config.tw.users.tim.colorScheme.palette.base01};
    opacity: 0.8;
    border-radius: 10px;
    border-width: 2px;
    border-style: solid;
    border-color: #${config.tw.users.tim.colorScheme.palette.base08};
}

tooltip label{
    color: #${config.tw.users.tim.colorScheme.palette.base04};
}

#taskbar button {
    color: #${config.tw.users.tim.colorScheme.palette.base05};
}

#taskbar button:hover {
  background: #${config.tw.users.tim.colorScheme.palette.base05};
    color: #${config.tw.users.tim.colorScheme.palette.base01};
}

#taskbar button.active {
    color: #${config.tw.users.tim.colorScheme.palette.base05};
    background: #${config.tw.users.tim.colorScheme.palette.base02};
    border-radius: 10px;
}

#workspaces button {
    padding: 5px;
    color: #${config.tw.users.tim.colorScheme.palette.base05};
    margin-right: 5px;
}

#workspaces button.active {
    color: #${config.tw.users.tim.colorScheme.palette.base05};
    background: #${config.tw.users.tim.colorScheme.palette.base02};
    border-radius: 10px;
}

#workspaces button:hover {
    background: #${config.tw.users.tim.colorScheme.palette.base05};
    color: #${config.tw.users.tim.colorScheme.palette.base01};
    border-radius: 10px;
}

#custom-launch_wofi,
#custom-launch_firefox,
#custom-launch_thunderbird,
#custom-launch_thunar,
#custom-launch_kitty,
#custom-lock_screen,
#custom-light_dark,
#custom-power_btn,
#power-profiles-deamon,
#custom-weather,
#custom-myhyprv,
#window,
#cpu,
#disk,
#custom-updates,
#memory,
#clock,
#battery,
#pulseaudio,
#network,
#tray,
#temperature,
#workspaces,
#idle_inhibitor,
#backlight {
    background: #${config.tw.users.tim.colorScheme.palette.base00};
    opacity: 1;
    padding: 0px 8px;
    margin: 0px 3px;
    border: 0px;
}

#workspaces {
    padding-right: 0px;
    padding-left: 5px;
}

#window {
    border-radius: 10px;
    margin-left: 0px;
    margin-right: 0px;
}

#custom-launch_firefox, 
#custom-launch_thunderbird,
#custom-launch_thunar,
#custom-launch_wofi,
#custom-launch_kitty,
#custom-weather {
    margin-left: 0px;
    border-right: 0px;
    font-size: 24px;
    margin-right: 20px;
}

#custom-launch_firefox, 
#custom-launch_kitty {
    font-size: 20px;
}
        '';
      };

      programs.wlogout.enable = true;

      home.packages = with pkgs; [
        libnotify
      ];
    };
  };
}
