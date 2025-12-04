{ pkgs, config, lib, ... }: {
  config = lib.mkIf config.tw.users.tim.ui.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      rocmOverrideGfx = "11.0.2";
    };
  };
}
