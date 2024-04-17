{ lib
, pkgs
, config
, inputs
, ...
}: {
  home-manager = {
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
              "temperature"
              "custom/power_profile"
              "battery"
              "pulseaudio"
              "backlight"
              "tray"
              "custom/weather"
              "clock"
            ];

            "custom/launch_wofi" = {
              format = "";
              on-click = "pkill wofi || wofi";
              tooltip = false;
            };

            "custom/power_btn" = {
              # TODO make this a menu of options
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
              disable-scroll = true;
              all-outputs = false;
              on-click = "activate";
              persistent_workspaces = { };
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
              on-click = "~/.config/hyprv4/scripts/volume --toggle";
              on-click-right = "pavucontrol";
              on-scroll-up = "~/.config/hyprv4/scripts/volume --inc";
              on-scroll-down = "~/.config/hyprv4/scripts/volume --dec";
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

            clock = {
              format = " {:%I:%M %p   %m/%d/%Y}";
            };

            backlight = {
              format = "{icon} {percent}%";
              format-icons = [ "󰃞" "󰃟" "󰃠" ];
              on-scroll-up = "~/.config/HyprV/waybar/scripts/brightness --inc";
              on-scroll-down = "~/.config/HyprV/waybar/scripts/brightness --dec";
            };

            tray = {
              icon-size = 16;
              spacing = 10;
            };
          };
        };
        style = ./hyprv4/waybar/style/v4-style-dark.css;
      };
    };
  };
}
