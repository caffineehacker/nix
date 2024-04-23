{ lib
, pkgs
, config
, inputs
, ...
}: {
  imports = [ ./wofi.nix ./waybar.nix ./swaylock.nix ];
  config = lib.mkIf config.tw.programs.hyprland.enable {
    fonts.packages = with pkgs; [
      noto-fonts-emoji
      nerdfonts
    ];

    colorScheme = inputs.nix-colors.colorSchemes.solarized-dark;

    # Enable swaylock to authenticate with pam
    security.pam.services.swaylock = { };

    home-manager = {
      users.tim = {
        home.packages = with pkgs; [
          networkmanagerapplet
          wl-clipboard
          swww
          mako
          pamixer
          cliphist
          xfce.thunar
          brightnessctl
          swayidle
        ];

        xdg.configFile."hyprv4/scripts" = {
          recursive = true;
          source = ./hyprv4/scripts;
        };

        xdg.configFile."hyprv4/backgrounds" = {
          recursive = true;
          source = ./hyprv4/backgrounds;
        };

        services.wlsunset = {
          enable = true;
          latitude = "47.7";
          longitude = "-122.4";
        };

        wayland.windowManager.hyprland = {
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
              "float, ^([t|T]hunar)$"
            ];
            windowrulev2 = [
              "opacity 0.8 0.8,class:^(kitty)$"
              "animation popin,class:^(kitty)$,title:^(update-sys)$"
              "animation popin,class:^([t|T]hunar)$"
              "opacity 0.8 0.8,class:^([t|T]hunar)$"
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

              "ALT, TAB, overview:toggle"

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
              builtins.concatLists (builtins.genList
                (
                  x:
                  let
                    ws = builtins.toString (x + 1);
                    key = builtins.toString (if x < 9 then x + 1 else 0);
                  in
                  [
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
              # Automatic brightness control
              "wluma"
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
            inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
          ];
        };
      };
    };
  };
}
