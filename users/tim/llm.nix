{config, lib, ...}: {
  config = lib.mkIf config.tw.users.tim.ui.enable {
    services.ollama = {
      enable = true;
      acceleration = "rocm";
    };
  };
}