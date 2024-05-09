{
  description = "flake for framework laptop";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      # Make sure we pick a rev with hydra builds
      rev = "b211b392b8486ee79df6cdfb1157ad2133427a29"; ### REPLACE_NIXPKGS_REV
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
      ref = "v0.40.0"; ### REPLACE_HYPRLAND_TAG
      inputs.nixpkgs.follows = "nixpkgs";
    };
    split-monitor-workspaces = {
      type = "github";
      owner = "Duckonaut";
      repo = "split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
      rev = "b40147d96d62a9e9bbc56b18ea421211ee598357";
    };
    hyprland-plugins = {
      type = "github";
      owner = "hyprwm";
      repo = "hyprland-plugins";
      rev = "18daf37b7c4e6e51ca2bf8953ce4cff1c38ca725";
      inputs.hyprland.follows = "hyprland";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    inputmodule-control = {
      url = "./flakes/inputmodule-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          # originPkgs = inputs.nixpkgs.legacyPackages.${system};
          # nixpkgs = originPkgs.applyPatches {
          #   name = "nixpkgs-patched";
          #   src = inputs.nixpkgs;
          #   # Binutils patch allows LTO when linking - Adapted from https://github.com/NixOS/nixpkgs/pull/188544
          #   # Static link patch fixes the adapter for static linking to use the right linking variable. This is my own patch.
          #   patches = [ 
          #     ./binutils_first.patch
          #     # ./static_link.patch
          #   ];
          # };
          # nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
          nixosSystem = inputs.nixpkgs.lib.nixosSystem;
        in nixosSystem {
          inherit system;
          specialArgs = { inherit inputs system; };
          modules = commonModules ++ [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                inputs.hyprland.overlays.default
                inputs.inputmodule-control.overlays.default
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
