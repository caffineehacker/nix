{ config, lib, inputs, pkgs, ... }:
let
  cfg = config.tw.users.tim;
  uiEnabled = cfg.ui.enable;
  inherit (inputs.nix-colors.lib.contrib { inherit pkgs; })
    gtkThemeFromScheme;
in
{
  options = {
    tw.users.tim.ui.enable = lib.mkOption {
      default = (config.services.xserver.enable || config.tw.programs.hyprland.enable) && cfg.enable;
      example = true;
      description = ''
        Enable UI based settings
      '';
      type = lib.types.bool;
    };
  };
  config = lib.mkIf (uiEnabled && cfg.enable) {
    fonts.packages = with pkgs; [
      noto-fonts-emoji
    ] ++ (builtins.filter
      lib.attrsets.isDerivation
      (builtins.attrValues pkgs.nerd-fonts));

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
        element-desktop
        obsidian
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
        profiles.default = {
          userSettings = {
            "workbench.colorTheme" = "Catppuccin Frappé";

            "git.autofetch" = true;
            "git.enableSmartCommit" = true;
            "git.confirmSync" = false;

            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nil";

            "editor.formatOnSave" = true;
            "files.autoSave" = "onFocusChange";
            "continue.telemetryEnabled" = false;
          };
          extensions =
            let
              continue-dev = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
                mktplcRef = {
                  name = "continue";
                  publisher = "Continue";
                  version = "0.9.163";
                  hash = "sha256-jZ8MOOrkZ9tJq6qxzoveZnJmNQQg/vbnBBxxeJx2O8A=";
                };
                meta = {
                  changelog = "https://marketplace.visualstudio.com/items?itemName=Continue.continue/changelog";
                  description = "Ollama frontend";
                  downloadPage = "https://marketplace.visualstudio.com/items?itemName=Continue.continue";
                  homepage = "https://continue.dev";
                };
              };
            in
            with pkgs; [
              vscode-extensions.jnoortheen.nix-ide
              vscode-extensions.catppuccin.catppuccin-vsc
              continue-dev
            ];
        };
      };

      services.gnome-keyring.enable = true;

      programs.gpg.enable = true;
    };

    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    environment.systemPackages = with pkgs; [
      pinentry-gnome3
    ];
  };
}
