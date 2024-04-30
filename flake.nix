{
  description = "flake for framework laptop";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      type = "github";
      owner = "hyprwm";
      repo = "Hyprland";
      # Current head changed a lot of protocols and doesn't work properly with everything.
      ref = "v0.39.1"; ### REPLACE_HYPRLAND_TAG
    };
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, lanzaboote, home-manager, hyprland, ... }@inputs:
    let
      commonModules = [
        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [
            hyprland.overlays.default
          ];
        })
        lanzaboote.nixosModules.lanzaboote
        ./system
        ./programs
        ./users
      ];
    in
    {
      nixosConfigurations = {
        framework = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; system = "x86_64-linux"; };
          modules = commonModules ++ [
            ./machines/framework
          ];
        };
        homeauto = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; system = "aarch64-linux"; };
          modules = commonModules ++ [
            ./machines/homeauto
          ];
        };
      };
    };
}
