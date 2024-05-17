{ lib
, pkgs
, config
, inputs
, ...
}:
let
  cfg = config.tw.users.tim;
  inherit (inputs.nix-colors.lib.contrib { inherit pkgs; })
    gtkThemeFromScheme;
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
      default = inputs.nix-colors.colorSchemes.catppuccin-frappe;
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

    home-manager = {
      users.tim = {
        home.username = "tim";
        home.homeDirectory = "/home/tim";
        home.stateVersion = "23.05";

        gtk = {
          enable = true;
          theme = {
            name = "${cfg.colorScheme.slug}";
            package = gtkThemeFromScheme { scheme = cfg.colorScheme; };
          };
        };

        home.packages = with pkgs; [
          firefox-bin
          tree
          discord
          # Enables fish starting when using nix-shell
          nix-your-shell
          # Language server for Nix code
          nil
          # Formatter for Nix code
          nixpkgs-fmt
          (lib.mkIf config.tw.programs.games.enable protonup)
          (lib.mkIf config.tw.services.ssh.enable byobu)
          (lib.mkIf config.tw.services.ssh.enable tmux)
        ];

        home.sessionVariables = lib.mkIf config.tw.programs.games.enable {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS =
            "\\\${HOME}/.steam/root/compatibilitytools.d";
          MANGOHUD = "1";
        };

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

    users.users.tim = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        # Allows serial port access
        "dialout"
        "input"
      ];
      openssh.authorizedKeys.keys = [
        # Juice
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIyA+pkw1odhFbmruA2HsQgUKqJp04ewiw60OPeW/K7"
        # Framework
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICHMR1/H8/FaR+PV2kqWCIwM9ushx8k1ZWqHtffusqyV"
      ];
    };
  };
}
