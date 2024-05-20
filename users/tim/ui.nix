{config, lib, inputs, pkgs, ...}:
let
  cfg = config.tw.users.tim;
  uiEnabled = config.services.xserver.enable || config.tw.programs.hyprland.enable;
  inherit (inputs.nix-colors.lib.contrib { inherit pkgs; })
    gtkThemeFromScheme;
in {
  config = lib.mkIf (uiEnabled && cfg.enable) {
    fonts.packages = with pkgs; [
      noto-fonts-emoji
      nerdfonts
    ];

    home-manager.users.tim = {
      gtk = {
        enable = true;
        theme = {
          name = "${cfg.colorScheme.slug}";
          package = gtkThemeFromScheme { scheme = cfg.colorScheme; };
        };
      };

      home.packages = with pkgs; [
        firefox-bin
        discord
      ];

      programs.kitty = {
        enable = true;
        settings = {
          foreground = "#${cfg.colorScheme.palette.base05}";
          background = "#${cfg.colorScheme.palette.base00}";
        };
      };

      programs.vscode = {
        enable = true;
        package = pkgs.vscodium-fhs;
        userSettings = {
          "workbench.colorTheme" = "Catppuccin Frappé";

          "git.autofetch" = true;
          "git.enableSmartCommit" = true;
          "git.confirmSync" = false;

          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nil";

          "editor.formatOnSave" = true;
          "files.autoSave" = "onFocusChange";
        };
        extensions = with pkgs; [
          vscode-extensions.jnoortheen.nix-ide
          vscode-extensions.catppuccin.catppuccin-vsc
        ];
      };
    };
  };
}