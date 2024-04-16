{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  cfg = config.tw.users.tim;
in {
  imports = [
    ../home-manager.nix
    inputs.nix-colors.homeManagerModules.default
  ];

  options = {
    tw.users.tim.enable = lib.mkOption {
      default = true;
      example = true;
      description = ''
        Enable user tim
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    tw.users.home-manager.enable = true;

    fonts.packages = with pkgs; [
      noto-fonts-emoji
      nerdfonts
    ];

    colorScheme = inputs.nix-colors.colorSchemes.nord;

    # Enable swaylock to authenticate with pam
    security.pam.services.swaylock = lib.mkIf config.tw.programs.hyprland.enable {};

    home-manager = {
      users.tim = {
        home.username = "tim";
        home.homeDirectory = "/home/tim";
        home.stateVersion = "23.05";

        home.packages = with pkgs; [
          firefox
          tree
          vscodium-fhs
          discord
        ] ++ (if config.tw.programs.hyprland.enable then [
          networkmanagerapplet
          wl-clipboard
          swww
          mako
          swaylock
          pamixer
          cliphist
          xfce.thunar
          brightnessctl
          swayidle
        ] else []);

        xdg.configFile."hyprv4/scripts" = lib.mkIf config.tw.programs.hyprland.enable {
          recursive = true;
          source = ./hyprv4/scripts;
        };

        xdg.configFile."hyprv4/backgrounds" = lib.mkIf config.tw.programs.hyprland.enable {
          recursive = true;
          source = ./hyprv4/backgrounds;
        };

        programs.kitty = {
          enable = true;
          settings = {
            foreground = "#${config.colorScheme.palette.base05}";
            background = "#${config.colorScheme.palette.base00}";
          };
        };

        wayland.windowManager.hyprland = lib.mkIf config.tw.programs.hyprland.enable {
          enable = true;
          settings = {
            monitor = ",preferred,auto,1,vrr,1";
            "$terminal" = "kitty";
            env = [
              "XCURSOR_SIZE,48"
              "QT_QPA_PLATFORMTHEME,qt6ct"
              "XDG_CURRENT_DESKTOP,Hyprland"
              "XDG_SESSION_TYPE,wayland"
              "XDG_SESSION_DESKTOP,Hyprland"
            ];
            input = {
              kb_layout = "us";
              follow_mouse = 1;
              touchpad = {
                natural_scroll = false;
              };
            };
            general = {
              gaps_in = 5;
              gaps_out = 10;
              border_size = 2;
              "col.active_border" = "rgb(cdd6f4)";
              "col.inactive_border" = "rgba(595959aa)";
              layout = "dwindle";
            };
            decoration = {
              rounding = 5;
              blur = {
                enabled = true;
                size = 7;
                passes = 4;
                new_optimizations = true;
              };
              blurls = "lockscreen";

              drop_shadow = true;
              shadow_range = 4;
              shadow_render_power = 3;
              "col.shadow" = "rgba(1a1a1aee)";
            };
            animations = {
              enabled = true;
              bezier = "myBezier, 0.10, 0.9, 0.1, 1.05";

              animation = [
                "windows, 1, 7, myBezier, slide"
                "windowsOut, 1, 7, myBezier, slide"
                "border, 1, 10, default"
                "fade, 1, 7, default"
                "workspaces, 1, 6, default"
              ];
            };
            dwindle = {
              pseudotile = true;
              preserve_split = true;
            };
            master = {
              new_is_master = true;
            };
            gestures = {
              workspace_swipe = true;
            };
            windowrule = [
              "float,^(blueman-manager)$"
              "float,^(nm-connection-editor)$"
              "float, ^(pavucontrol)$"
              "float, ^(thunar)$"
            ];
            windowrulev2 = [
              "opacity 0.8 0.8,class:^(kitty)$"
              "animation popin,class:^(kitty)$,title:^(update-sys)$"
              "animation popin,class:^(thunar)$"
              "opacity 0.8 0.8,class:^(thunar)$"
              "opacity 0.8 0.8,class:^(VSCodium)$"
              "move cursor -3% -105%,class:^(wofi)$"
              "noanim,class:^(wofi)$"
              "opacity 0.8 0.6,class:^(wofi)$"
            ];
            misc = {
              force_default_wallpaper = -1;
            };

            "$mod" = "SUPER";
            bind = [
              "$mod, Return, exec, $terminal"
              "$mod, F4, killactive,"
              "$mod, Q, exit,"
              "$mod, L, exec, swaylock"
              "$mod, E, exec, $fileManager"
              "$mod, F, togglefloating,"
              "$mod, SPACE, exec, wofi"
              "$mod SHIFT, F, fullscreen"
              # clipboard manager
              "ALT, V, exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy"

              "$mod, left, movefocus, l"
              "$mod, right, movefocus, r"
              "$mod, up, movefocus, u"
              "$mod, down, movefocus, d"

              "$mod, grave, hyprexpo:expo, toggle"

              # Media key binds
              ", xf86audioraisevolume, exec, ~/.config/hyprv4/scripts/volume --inc"
              ", xf86audiolowervolume, exec, ~/.config/hyprv4/scripts/volume --dec"
              ", xf86AudioMicMute, exec, ~/.config/hyprv4/scripts/volume --toggle-mic"
              ", xf86audioMute, exec, ~/.config/hyprv4/scripts/volume --toggle"

              ", xf86KbdBrightnessDown, exec, ~/.config/hyprv4/scripts/kb-brightness --dec"
              ", xf86KbdBrightnessUp, exec, ~/.config/hyprv4/scripts/kb-brightness --inc"
              ", xf86MonBrightnessDown, exec, ~/.config/hyprv4/scripts/brightness --dec"
              ", xf86MonBrightnessUp, exec, ~/.config/hyprv4/scripts/brightness --inc"
            ] ++ (
              # workspaces
              # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
              builtins.concatLists (builtins.genList (
                  x: let
                    ws = builtins.toString (x + 1);
                    key = builtins.toString (if x < 9 then x + 1 else 0);
                  in [
                    "$mod, ${key}, split-workspace, ${ws}"
                    "$mod SHIFT, ${key}, split-movetoworkspacesilent, ${ws}"
                  ]
                )
                10)
            );

            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
              "$mod SHIFT, mouse:272, resizewindow"
            ]; 

            bindl = [
              ",switch:[Lid Switch],exec,swaylock"
            ];

            exec-once = [
              "firefox"
              "swww-daemon"
              "mako"
              "blueman-applet"
              "nm-applet --indicator"
              "wl-paste --watch cliphist store"
              "waybar"
              "steam"
              # Enable sway lock when the system sleeps
              "swayidle -w before-sleep \"swaylock -f\""
            ];

            exec = [
              "swww img ~/.config/hyprv4/backgrounds/v1-background-dark.jpg"
            ];

            # Temporary fix for https://github.com/Alexays/Waybar/issues/2666
            # Should be fixed in next swaybar release
            general = {
              no_cursor_warps = true;
            };

            plugin = {
              split-monitor-workspaces = {
                count = 10;
              };
              hyprexpo = {
                columns = 3;
                gap_size = 5;
                bg_col = "rgb(111111)";
                workspace_method = "center current";
                enable_gesture = true;
                gesture_distance = 300;
                gesture_positive = true;
              };
            };
          };

          plugins = [
            inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
            inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
            inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
          ];
        };

        programs.wofi = lib.mkIf config.tw.programs.hyprland.enable {
          enable = true;
          settings = {
            width = 600;
            height = 300;
            location = "center";
            show = "drun";
            prompt = "Search...";
            filter_rate = 100;
            allow_markup = true;
            no_actions = true;
            halign = "fill";
            orientation = "vertical";
            content_haligh = "fill";
            insensitive = true;
            allow_images = true;
            image_size = 40;
            gtk_dark = true;
            dynamic_lines = true;
          };
          style = builtins.readFile ./hyprv4/wofi/style/v4-style-dark.css;
        };

        programs.swaylock = lib.mkIf config.tw.programs.hyprland.enable {
          enable = true;
          settings = {
            daemonize = true;
            show-failed-attempts = true;
            screenshot = true;
            effect-blur = "9x5";
            effect-vignette = "0.5:0.5";
            color = "1f1d2e80";
            font = "Inter";
            indicator = true;
            indicator-radius = 200;
            indicator-thickness = 20;
            line-color = "1f1d2e";
            ring-color = "191724";
            inside-color = "1f1d2e";
            key-hl-color = "eb6f92";
            separator-color = "00000000";
            text-color = "e0def4";
            text-caps-lock-color = "";
            line-ver-color = "eb6f92";
            ring-ver-color = "eb6f92";
            inside-ver-color = "1f1d2e";
            text-ver-color = "e0def4";
            ring-wrong-color = "31748f";
            text-wrong-color = "31784f";
            inside-wrong-color = "1f1d2e";
            inside-clear-color = "1f1d2e";
            text-clear-color = "e0def4";
            ring-clear-color = "9ccfd8";
            line-clear-color = "1f1d2e";
            line-wrong-color = "1f1d2e";
            bs-hl-color = "31748f";
            grace = 2;
            grace-no-mouse = true;
            grace-no-touch = true;
            datestr = "%a, %B %e";
            timestr = "%I:%M %p";
            fade-in = 0.2;
            ignore-empty-password = true;
          };
        };

        programs.waybar = lib.mkIf config.tw.programs.hyprland.enable {
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
                "pulseaudio#microphone"
                "backlight"
                "tray"
                "custom/weather"
                "custom/updates"
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
                persistent_workspaces = {
                };
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
                format = "";
                max-length = 10;
                format-alt-click = "click-right";
                format-alf = " {usage}%";
                on-click = "kitty --start-as=fullscreen --title btop sh -c 'btop'";
              };

              memory = {
                interval = 30;
                format = "";
                format-alt-click = "click-right";
                format-alt = " {}%";
                max-length = 10;
                tooltip = true;
                tooltip-format = "Memory - {used:0.1f}GB used";
                on-click = "kitty --start-as=fullscreen --title btop sh -c 'btop'";
              };

              disk = {
                interval = 30;
                format = "󰋊";
                path = "/";
                format-alt-click = "click-right";
                format-alt = "󰋊 {percentage_used}%";
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
                format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
              };

              pulseaudio = {
                format = "{icon}";
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
                  default = ["" "" ""];
                };
                tooltip = true;
                tooltip-format = "{icon} at {volume}%";
              };

              clock = {
                format = "{%r}";
              };

              # TODO: microphone and backlight

              tray = {
                icon-size = 16;
                spacing = 10;
              };
            };
          };
          style = ./hyprv4/waybar/style/v4-style-dark.css;
        };

        services.wlsunset = lib.mkIf config.tw.programs.hyprland.enable {
          enable = true;
          latitude = "47.7";
          longitude = "-122.4";
        };

        programs.git = {
          enable = true;
          userName = "Tim Waterhouse";
          userEmail = "tim@timwaterhouse.com";
        };

        programs.fish.enable = true;
        programs.btop.enable = true;

        programs.home-manager.enable = true;
      };
    };

    users.users.tim = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
    };


  };
}
