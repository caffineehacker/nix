{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.tw.users.tim;
in {
  options = {
    tw.users.tim.enable = lib.mkOption {
      default = true;
      example = true;
      description = ''
        Enable the tim user
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.tim = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      packages = with pkgs; [
        firefox
        tree
        kitty
        fish
        vscodium-fhs
        discord
      ];
    };
  };
}