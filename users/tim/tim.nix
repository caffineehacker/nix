{ lib
, pkgs
, config
, inputs
, ...
}:
let
  cfg = config.tw.users.tim;
in
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ./hyprland
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

    tw.users.tim.colorScheme = lib.mkOption {
      default = inputs.nix-colors.colorSchemes.solarized-dark;
      description = ''
        The Nix colors color scheme to use
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    tw.users.home-manager.enable = true;

    fonts.packages = with pkgs; [
      noto-fonts-emoji
      nerdfonts
    ];

    # Enable swaylock to authenticate with pam
    security.pam.services.swaylock = lib.mkIf config.tw.programs.hyprland.enable { };

    home-manager = {
      users.tim = {
        home.username = "tim";
        home.homeDirectory = "/home/tim";
        home.stateVersion = "23.05";

        home.packages = with pkgs; [
          firefox
          tree
          discord
          # Enables fish starting when using nix-shell
          nix-your-shell
          # Language server for Nix code
          nil
          # Formatter for Nix code
          nixpkgs-fmt
        ];

        programs.kitty = {
          enable = true;
          settings = {
            foreground = "#${cfg.colorScheme.palette.base05}";
            background = "#${cfg.colorScheme.palette.base00}";
          };
        };

        programs.git = {
          enable = true;
          userName = "Tim Waterhouse";
          userEmail = "tim@timwaterhouse.com";
        };

        programs.fish = {
          enable = true;
          # This makes it so nix-shell will use fish
          interactiveShellInit = ''
            nix-your-shell fish | source
          '';
        };
        programs.btop.enable = true;

        programs.home-manager.enable = true;

        programs.vscode = {
          enable = true;
          package = pkgs.vscodium-fhs;
          userSettings = {
            "workbench.colorTheme" = "Solarized Dark";

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
          ];
        };
      };
    };

    users.users.tim = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        # Allows serial port access
        "dialout"
      ];
    };
  };
}
