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
    ./ui.nix
    ./llm.nix
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

    home-manager = {
      users.tim = {
        home.username = "tim";
        home.homeDirectory = "/home/tim";
        home.stateVersion = "23.05";

        home.packages = with pkgs; [
          tree
          # Enables fish starting when using nix-shell
          nix-your-shell
          # Language server for Nix code
          nil
          # Formatter for Nix code
          nixpkgs-fmt
          (lib.mkIf config.tw.programs.games.enable protonup)
          (lib.mkIf config.tw.services.ssh.enable byobu)
          (lib.mkIf config.tw.services.ssh.enable tmux)
          killall
          thunderbird
          ncdu
          gitui
          inputs.isd.packages.x86_64-linux.default
        ];

        home.sessionVariables = lib.mkIf
          config.tw.programs.games.enable
          {
            STEAM_EXTRA_COMPAT_TOOLS_PATHS =
              "\\\${HOME}/.steam/root/compatibilitytools.d";
            MANGOHUD = "1";
          };

        programs.git = {
          enable = true;
          userName = "Tim Waterhouse";
          userEmail = "tim@timwaterhouse.com";

          extraConfig = {
            commit.gpgsign = true;
            user.signingKey = "0BA5979146BB1B42";
          };
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

        programs.ssh = {
          enable = true;
          matchBlocks = lib.mkIf config.tw.services.ssh.enable {
            "homelab.timwaterhouse.com" = {
              proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
            };
          };
        };

        # Fix issue with permissions being wrong on .ssh/config
        home.file.".ssh/config" = {
          target = ".ssh/config_source";
          onChange = ''cat ~/.ssh/config_source > ~/.ssh/config && chmod 400 ~/.ssh/config'';
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
