{ lib
, pkgs
, config
, inputs
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

  imports = [ inputs.hyprland.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;
    environment.sessionVariables = {
      # Try to get Electron apps to use Wayland
      NIXOS_OZONE_WL = "1";
    };

    # For screen sharing
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
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
      xdg-desktop-portal-hyprland
      xwayland
      meson
      wayland-protocols
      wayland-utils
      wlroots
      pavucontrol
    ];

    # Use sddm display manager
    services.displayManager.sddm.enable = true;
    services.xserver.enable = true;
  };
}
