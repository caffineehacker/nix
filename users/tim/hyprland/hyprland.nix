{ lib
, pkgs
, config
, ...
}: {
  imports = [ ./wofi.nix ./waybar.nix ./swaylock.nix ./mako.nix ./wlogout.nix ./scripts ];
  config = lib.mkIf config.tw.programs.hyprland.enable {
    nixpkgs.overlays = [
      (self: super: {
        gtk4-layer-shell = super.gtk4-layer-shell.overrideAttrs (oldAttrs: {
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ super.wayland-protocols ];
        });
      })
    ];
    fonts.packages = with pkgs; [
      noto-fonts-color-emoji
    ] ++ (builtins.filter
      lib.attrsets.isDerivation
      (builtins.attrValues pkgs.nerd-fonts));

    programs.dms-shell = {
      enable = true;
      systemd.enable = false;
      enableVPN = false;
      enableDynamicTheming = true;
      enableAudioWavelength = false;
      enableCalendarEvents = false;
    };

    home-manager = {
      users.tim = {
        home.packages = with pkgs; [
          # Even though this is only referred to as $pkgs.networkmanagerapplet, we need to install it for the icons to appear
          networkmanagerapplet
          pamixer
          thunar
          nordzy-cursor-theme
        ];

        xdg.mimeApps = {
          enable = true;
          associations.added = {
            "inode/directory" = [ "thunar.desktop" ];
          };
        };

        services.wlsunset = {
          enable = true;
          latitude = "47.7";
          longitude = "-122.4";
        };

        wayland.windowManager.hyprland = {
          enable = true;
          configType = "lua";
          settings = {
            mod = { _var = "SUPER"; };
            terminal = { _var = "alacritty"; };
            monitor = {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
              vrr = 2;
            };
            env = [{
              _args = [
                "XCURSOR_SIZE"
                48
              ];
            }
              {
                _args = [
                  "QT_QPA_PLATFORMTHEME"
                  "qt6ct"
                ];
              }
              {
                _args = [
                  "XDG_CURRENT_DESKTOP"
                  "Hyprland"
                ];
              }
              {
                _args = [
                  "XDG_SESSION_TYPE"
                  "wayland"
                ];
              }
              {
                _args = [
                  "XDG_SESSION_DESKTOP"
                  "Hyprland"
                ];
              }];
            config = {
              input = {
                kb_layout = "us";
                follow_mouse = 1;
                # Focus under mouse when closing a window
                focus_on_close = 1;
                touchpad = {
                  natural_scroll = false;
                };
                numlock_by_default = true;
              };
              general = {
                gaps_in = 5;
                gaps_out = 10;
                border_size = 2;
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

                shadow = {
                  enabled = true;
                  range = 4;
                  render_power = 3;
                };
              };
              animations = {
                enabled = true;
              };
              dwindle = {
                # pseudotile = true;
                preserve_split = true;
              };
              misc = {
                force_default_wallpaper = 0;
                focus_on_activate = true;
                disable_hyprland_logo = true;
                mouse_move_enables_dpms = true;
                key_press_enables_dpms = true;
              };
              cursor = {
                no_warps = true;
                # Attempt to fix issue where games start to lag whenever the mouse moves.
                no_hardware_cursors = 1;
                no_break_fs_vrr = 1;
              };
            };
            gesture = {
              fingers = 3;
              direction = "horizontal";
              action = "workspace";
            };
            window_rule = [
              {
                name = "blueman float";
                match = {
                  class = "^(blueman-manager)$";
                };
                float = true;
              }
              {
                name = "nm connection editor float";
                match = {
                  class = "^(nm-connection-editor)$";
                };
                float = true;
              }
              {
                name = "pavu float";
                match = {
                  class = "^(pavucontrol)$";
                };
                float = true;
              }
              {
                name = "thunar";
                match = {
                  class = "^([t|T]hunar)$";
                };
                float = true;
                animation = "popin";
                opacity = "0.8";
              }
              {
                name = "wofi";
                match = {
                  class = "^(wofi)$";
                };
                opacity = "0.8 0.6";
                move = "(cursor_x-(window_w*0.5)) (cursor_y-(window_h*0.5))";
              }

            ];
            bind =
              let
                mkBind =
                  (key: command: {
                    _args = [
                      (lib.generators.mkLuaInline "\"${key}\"")
                      (lib.generators.mkLuaInline command)
                    ];
                  });
                mkSBind =
                  (key: command: {
                    _args = [
                      (lib.generators.mkLuaInline "mod .. \"+ ${key}\"")
                      (lib.generators.mkLuaInline command)
                    ];
                  });
              in
              [
                (mkSBind "Return" "hl.dsp.exec_cmd(terminal)")
                (mkSBind "F4" "hl.dsp.window.close()")
                (mkSBind "Q" "hl.dsp.exec_cmd(\"hyprshutdown\")")
                (mkSBind "L" "function ()
                  hl.dsp.exec_cmd(\"${pkgs.swaylock}/bin/swaylock\")
                  hl.timer(function()
                    hl.dispatch(hl.dsp.dpms({ action = \"disable\" }))
                  end, {timeout = 500, type = \"oneshot\"})
                end
                  ")
                (mkSBind "F" "hl.dsp.window.float({action = toggle})")
                (mkSBind "SHIFT + F" "hl.dsp.window.fullscreen({action = toggle})")
                (mkSBind "SPACE" "hl.dsp.exec_cmd(\"wofi\")")

                # Screenshots
                # Screenshot a window
                (mkSBind "PRINT" "hl.dsp.exec_cmd(\"${pkgs.hyprshot}/bin/hyprshot -m window\")")
                # Screenshot a monitor
                (mkBind "PRINT" "hl.dsp.exec_cmd(\"${pkgs.hyprshot}/bin/hyprshot -m output\")")
                # Screenshot a region
                (mkSBind "SHIFT + PRINT" "hl.dsp.exec_cmd(\"${pkgs.hyprshot}/bin/hyprshot -m region\")")
                # clipboard manager
                (mkSBind "V" "hl.dsp.exec_cmd(\"${pkgs.cliphist}/bin/cliphist list | wofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy\")")

                (mkSBind "left" "hl.dsp.focus({direction = \"l\"})")
                (mkSBind "up" "hl.dsp.focus({direction = \"u\"})")
                (mkSBind "right" "hl.dsp.focus({direction = \"r\"})")
                (mkSBind "down" "hl.dsp.focus({direction = \"d\"})")

                # Media key binds
                (mkBind "xf86audioraisevolume" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.volume}/bin/volume --inc\")")
                (mkBind "xf86audiolowervolume" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.volume}/bin/volume --dec\")")
                (mkBind "xf86AudioMicMute" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.volume}/bin/volume --toggle-mic\")")
                (mkBind "xf86audioMute" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.volume}/bin/volume --toggle\")")

                (mkBind "xf86KbdBrightnessDown" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.kb-brightness}/bin/kb-brightness --dec\")")
                (mkBind "xf86KbdBrightnessUp" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.kb-brightness}/bin/kb-brightness --inc\")")
                (mkBind "xf86MonBrightnessDown" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.kb-brightness}/bin/brightness --dec\")")
                (mkBind "xf86MonBrightnessUp" "hl.dsp.exec_cmd(\"${pkgs.tw.hypr.kb-brightness}/bin/brightness --inc\")")

                {
                  _args = [
                    (lib.generators.mkLuaInline "mod .. \" + mouse:272\"")
                    (lib.generators.mkLuaInline "hl.dsp.window.drag()")
                    (lib.generators.mkLuaInline "{ mouse = true }")
                  ];
                }
                {
                  _args = [
                    (lib.generators.mkLuaInline "mod .. \" + mouse:273\"")
                    (lib.generators.mkLuaInline "hl.dsp.window.resize()")
                    (lib.generators.mkLuaInline "{ mouse = true }")
                  ];
                }

                {
                  _args = [
                    (lib.generators.mkLuaInline "\"switch:[Lid Switch]\"")
                    (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"swaylock\")")
                    (lib.generators.mkLuaInline "{ locked = true }")
                  ];
                }
              ] ++ (
                # workspaces
                # binds mod + [shift +] {1..10} to [move to] workspace {1..10}
                builtins.concatLists (builtins.genList
                  (
                    x:
                    let
                      ws = builtins.toString (x + 1);
                      key = builtins.toString (if x < 9 then x + 1 else 0);
                    in
                    [
                      # "mod, ${key}, split:workspace, ${ws}"
                      # "mod SHIFT, ${key}, split:movetoworkspacesilent, ${ws}"
                      (mkSBind "${key}" "hl.dsp.focus({workspace = \"${ws}\"})")
                      (mkSBind "SHIFT + ${key}" "hl.dsp.window.move({workspace = \"${ws}\", follow = false})")
                    ]
                  )
                  10)
              );

            on = {
              _args = [
                (lib.generators.mkLuaInline "\"hyprland.start\"")
                (lib.generators.mkLuaInline ("function()
                " + (builtins.concatStringsSep "\n" (map (x: "hl.exec_cmd(\"${x}\")") [
                  "hyprctl setcursor Nordzy-cursors 24"
                  "firefox"
                  "${pkgs.awww}/bin/awww-daemon"
                  "mako"
                  "${pkgs.blueman}/bin/blueman-applet"
                  "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"
                  "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store"
                  "dms run -d"
                  "steam"
                  # Enable sway lock when the system sleeps
                  "${pkgs.swayidle}/bin/swayidle -w before-sleep \\\"swaylock -f\\\""
                  "${pkgs.discord}/bin/discord"
                  "${pkgs.easyeffects}/bin/easyeffects --gapplication-service"
                  "${pkgs.awww}/bin/awww img ${config.stylix.image}"
                ])) +
                "
              end
              "))
              ];
            };
          };
          extraConfig = "
          require(\"dms.layout\")
          require(\"dms.outputs\")
          require(\"dms.windowrules\")
          ";
        };
      };
    };
  };
}
