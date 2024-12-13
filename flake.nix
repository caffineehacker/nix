{
  description = "flake for my Nix setups";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixpkgs-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";

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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      # Current head changed a lot of protocols and doesn't work properly with everything.
      ref = "refs/tags/v0.45.2"; ### REPLACE_HYPRLAND_TAG
      submodules = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    split-monitor-workspaces = {
      type = "github";
      owner = "Duckonaut";
      repo = "split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
      rev = "131bc5bd02d7f558a66d1a6c4d0013d8545823e0"; ### REPLACE_SPLIT_MONITOR_REV
    };
    hyprland-plugins = {
      type = "github";
      owner = "hyprwm";
      repo = "hyprland-plugins";
      ref = "refs/tags/v0.45.0"; ### REPLACE_HYPRLAND_PLUGINS_TAG
      inputs.hyprland.follows = "hyprland";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    nixos-hardware = {
      type = "github";
      owner = "NixOS";
      repo = "nixos-hardware";
    };
    inputmodule-control = {
      url = "github:caffineehacker/nix?dir=flakes/inputmodule-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      commonModules = [
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.sops-nix.nixosModules.sops
        ./system
        ./programs
        ./users
        ./services
        ./containers
        ./secrets
        ./flakes/kitchenowl
      ];
    in
    {
      nixosConfigurations = {
        framework =
          let
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
          in
          nixosSystem {
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
        homelab =
          let
            system = "x86_64-linux";
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs system; };
            modules = commonModules ++ [
              ./machines/homelab
            ];
          };
        cloud =
          let
            system = "aarch64-linux";
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs system; };
            modules = commonModules ++ [
              ./machines/cloud
            ];
          };
      };
    };
}
