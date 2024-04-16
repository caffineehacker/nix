{ lib, inputs, config, ... }:
let
  cfg = config.tw.users.home-manager;
in
{
  options = {
    tw.users.home-manager.enable = lib.mkOption {
      default = true;
      example = true;
      description = ''
        Enable to use home-manager
      '';
      type = lib.types.bool;
    };
  };

  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = lib.mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
    };
  };
}
