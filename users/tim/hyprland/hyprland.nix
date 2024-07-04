{ lib
, pkgs
, config
, inputs
, ...
}: {
  imports = [ ./wofi.nix ./waybar.nix ./swaylock.nix ./mako.nix ./wlogout.nix ./scripts ];
  config = lib.mkIf config.tw.programs.hyprland.enable {
    fonts.packages = with pkgs; [
      noto-fonts-emoji
      nerdfonts
    ];

    home-manager = {
      users.tim = {
        home.packages = with pkgs; [
          # Even though this is only referred to as $pkgs.networkmanagerapplet, we need to install it for the icons to appear
          networkmanagerapplet
          pamixer
          xfce.thunar
        ];

        xdg.mimeApps = {
          enable = true;
          associations.added = {
            "inode/directory" = ["thunar.desktop"];
          };
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
              new_status = true;
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
              force_default_wallpaper = 0;
              focus_on_activate = true;
              disable_hyprland_logo = true;
              mouse_move_enables_dpms = true;
              key_press_enables_dpms = true;
            };

            "$mod" = "SUPER";
            bind = [
              "$mod, Return, exec, $terminal"
              "$mod, F4, killactive,"
              "$mod, Q, exit,"
              "$mod, L, exec, swaylock"
              "$mod, L, exec, sleep 1 && hyprctl dispatch dpms off"
              "$mod, F, togglefloating,"
              "$mod, SPACE, exec, wofi"
              "$mod SHIFT, F, fullscreen"

              # Screenshots
              # Screenshot a window
              "$mod, PRINT, exec, ${pkgs.hyprshot}/bin/hyprshot -m window"
              # Screenshot a monitor
              ", PRINT, exec, ${pkgs.hyprshot}/bin/hyprshot -m output"
              # Screenshot a region
              "$mod SHIFT, PRINT, exec, ${pkgs.hyprshot}/bin/hyprshot -m region"
              # clipboard manager
              "$mod, V, exec, ${pkgs.cliphist}/bin/cliphist list | wofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"

              "$mod, left, movefocus, l"
              "$mod, right, movefocus, r"
              "$mod, up, movefocus, u"
              "$mod, down, movefocus, d"

              # Media key binds
              ", xf86audioraisevolume, exec, ${pkgs.tw.hypr.volume}/bin/volume --inc"
              ", xf86audiolowervolume, exec, ${pkgs.tw.hypr.volume}/bin/volume --dec"
              ", xf86AudioMicMute, exec, ${pkgs.tw.hypr.volume}/bin/volume --toggle-mic"
              ", xf86audioMute, exec, ${pkgs.tw.hypr.volume}/bin/volume --toggle"

              ", xf86KbdBrightnessDown, exec, ${pkgs.tw.hypr.kb-brightness}/bin/kb-brightness --dec"
              ", xf86KbdBrightnessUp, exec, ${pkgs.tw.hypr.kb-brightness}/bin/kb-brightness --inc"
              ", xf86MonBrightnessDown, exec, ${pkgs.tw.hypr.brightness}/bin/brightness --dec"
              ", xf86MonBrightnessUp, exec, ${pkgs.tw.hypr.brightness}/bin/brightness --inc"
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
              "${pkgs.swww}/bin/swww-daemon"
              "mako"
              "${pkgs.blueman}/bin/blueman-applet"
              "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"
              "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"
              "waybar"
              "steam"
              "obsidian"
              # Enable sway lock when the system sleeps
              "${pkgs.swayidle}/bin/swayidle -w before-sleep \"swaylock -f\""
            ];

            exec = let
              inherit (inputs.nix-colors.lib.contrib { inherit pkgs; })
                nixWallpaperFromScheme;
              wallpaper = nixWallpaperFromScheme {
                scheme = config.tw.users.tim.colorScheme;
                width = 2560;
                height = 1600;
                logoScale = 5.0;
              }; in [
              "swww img ${wallpaper}"
            ];

            plugin = {
              split-monitor-workspaces = {
                count = 10;
              };
            };

            cursor = {
              no_warps = true;
            };
          };

          plugins = [
            inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
            inputs.hyprland-plugins.packages.${pkgs.system}.hyprbars
          ];
        };
      };
    };
  };
}
