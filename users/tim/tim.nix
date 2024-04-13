{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.tw.users.tim;
in {
  imports = [
    ../home-manager.nix
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

    home-manager = {
      users.tim = {
        home.username = "tim";
        home.homeDirectory = "/home/tim";
        home.stateVersion = "23.05";

        home.packages = with pkgs; [
          firefox
          tree
          kitty
          vscodium-fhs
          discord
        ] ++ (if config.tw.programs.hyprland.enable then [
          networkmanagerapplet
          wl-clipboard
          swww
          mako
          waybar
          blueman
          swaylock
          pamixer
          cliphist
          wofi
          xfce.thunar
        ] else []);

        xdg.configFile."hyprv4/scripts" = lib.mkIf config.tw.programs.hyprland.enable {
          recursive = true;
          source = ./hyprv4/scripts;
        };

        wayland.windowManager.hyprland.enable = lib.mkIf config.tw.programs.hyprland.enable true;
        wayland.windowManager.hyprland.settings = lib.mkIf config.tw.programs.hyprland.enable {
          monitor = ",preferred,auto,1,vrr,1";
          "$terminal" = "kitty";
          env = [
            "XCURSOR_SIZE,24"
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
                  key = builtins.toString (if x < 10 then x + 1 else 0);
                in [
                  "$mod, ${ws}, workspace, ${ws}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
                ]
              )
              10)
          );

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
            "$mod SHIFT, mouse:272, resizewindow"
          ]; 

          exec-once = [
            "firefox"
            "swww init"
            "mako"
            "blueman-applet"
            "nm-applet --indicator"
            "wl-paste --watch cliphist store"
            "waybar"
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
        };

        programs.git = {
          enable = true;
          userName = "Tim Waterhouse";
          userEmail = "tim@timwaterhouse.com";
        };

        programs.fish.enable = true;

        programs.home-manager.enable = true;
      };
    };

    users.users.tim = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
    };


  };
}