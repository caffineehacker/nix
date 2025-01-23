{ config, lib, pkgs, ... }: {
  config = lib.mkIf config.tw.users.tim.ui.enable {
    services.ollama = {
      enable = true;
      # acceleration = "rocm";
      rocmOverrideGfx = "11.0.2";
      # Remove this and re-add acceleration = "rocm" once this is fixed
      # https://github.com/NixOS/nixpkgs/issues/375359
      package = pkgs.ollama-rocm;
    };
  };
}
