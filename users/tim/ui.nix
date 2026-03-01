{ config, lib, inputs, pkgs, ... }:
let
  cfg = config.tw.users.tim;
  uiEnabled = cfg.ui.enable;
in
{
  options = {
    tw.users.tim.ui.enable = lib.mkOption {
      default = config.tw.system.ui.enable && cfg.enable;
      example = true;
      description = ''
        Enable UI based settings
      '';
      type = lib.types.bool;
    };
  };
  config = lib.mkIf (uiEnabled && cfg.enable) {
    stylix.enable = true;
    stylix.image = pkgs.fetchurl {
      url = "https://getwallpapers.com/wallpaper/full/0/5/8/35975.jpg";
      hash = "sha256-01hpirLNkEaJ1zACu8Km1v2VG3H7Rgnx3zErOuufTbY=";
    };
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";

    fonts.packages = with pkgs;
      [
        noto-fonts-color-emoji
      ] ++ (builtins.filter
        lib.attrsets.isDerivation
        (builtins.attrValues pkgs.nerd-fonts));

    home-manager.users.tim = {
      gtk = {
        enable = true;
      };

      stylix.targets.gtk.enable = true;

      home.packages = with pkgs; [
        firefox-bin
        discord
        element-desktop
        obsidian
        thunderbird
      ];

      programs.kitty = {
        enable = true;
      };

      programs.alacritty = {
        enable = true;
        theme = "solarized_dark";
        settings = {
          window = {
            opacity = lib.mkForce 0.8;
          };
        };
      };

      programs.vscode = {
        enable = true;
        package = pkgs.vscodium-fhs;
        profiles.default = {
          userSettings = {
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
