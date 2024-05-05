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
      type = "github";
      owner = "Duckonaut";
      repo = "split-monitor-workspaces";
      rev = "b0ee3953eaeba70f3fba7c4368987d727779826a";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-plugins = {
      type = "github";
      owner = "hyprwm";
      repo = "hyprland-plugins";
      rev = "9971fec974a9d94a2a1b1d68d5ada5fc59fec053";
      inputs.hyprland.follows = "hyprland";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs: let
    commonModules = [
      inputs.lanzaboote.nixosModules.lanzaboote
      ./system
      ./programs
      ./users
    ];
    in {
      nixosConfigurations = {
        framework = let
          system = "x86_64-linux";
          originPkgs = inputs.nixpkgs.legacyPackages.${system};
          nixpkgs = originPkgs.applyPatches {
            name = "nixpkgs-patched";
            src = inputs.nixpkgs;
            # Binutils patch allows LTO when linking - Adapted from https://github.com/NixOS/nixpkgs/pull/188544
            # Static link patch fixes the adapter for static linking to use the right linking variable. This is my own patch.
            patches = [ ./binutils_first.patch ./static_link.patch ];
          };
          nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
        in nixosSystem {
          inherit system;
          specialArgs = { inherit inputs system; };
          modules = commonModules ++ [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                inputs.hyprland.overlays.default
              ];
            })
            ./machines/framework
          ];
        };
        homeauto = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs; system = "aarch64-linux"; };
          modules = commonModules ++ [
            ./machines/homeauto
          ];
        };
      };
    };
}
