{config, lib, ...}: {
  config = lib.mkIf config.tw.users.tim.ui.enable {
    services.ollama = {
      enable = true;
      acceleration = "rocm";
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = "11.0.2";
      };
    };
  };
}