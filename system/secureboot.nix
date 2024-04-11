{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.system.secure-boot;
in {
  options = {
    system.secure-boot.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable signing boot images using lanzaboote, and install useful tools for secure boot machines
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.bootspec.enable = true;

    environment.systemPackages = with pkgs; [
      # For debugging and troubleshooting Secure Boot.
      sbctl
      sbsigntool
    ];

    # Lanzaboote currently replaces the systemd-boot module.
    # This setting is usually set to true in configuration.nix
    # generated at installation time. So we force it to false
    # for now.
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };
}