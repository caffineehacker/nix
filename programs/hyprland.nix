{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.tw.programs.hyprland;
in
{
  options = {
    tw.programs.hyprland.enable = lib.mkOption {
      default = false;
      example = true;
      description = ''
        Enable hyprland
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
    };
    environment.sessionVariables = {
      # Try to get Electron apps to use Wayland
      NIXOS_OZONE_WL = "1";
    };

    # For screen sharing
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
    };

    # Waybar
    nixpkgs.overlays = [
      (self: super: {
        waybar = super.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      xwayland
      meson
      wayland-protocols
      wayland-utils
      wlroots
      pavucontrol
    ];

    # Use sddm display manager
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.xserver.enable = true;
  };
}
