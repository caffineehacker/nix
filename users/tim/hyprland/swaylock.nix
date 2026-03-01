{ lib
, config
, ...
}: {
  # Enable swaylock to authenticate with pam
  security.pam.services.swaylock = lib.mkIf config.tw.programs.hyprland.enable { };

  home-manager = lib.mkIf config.tw.programs.hyprland.enable {
    users.tim = {
      programs.swaylock = {
        enable = true;
        settings = {
          daemonize = true;
          show-failed-attempts = true;
          screenshot = true;
          effect-blur = "9x5";
          effect-vignette = "0.5:0.5";
          indicator = true;
          indicator-radius = 200;
          indicator-thickness = 20;
          grace = 2;
          grace-no-mouse = true;
          grace-no-touch = true;
          datestr = "%a, %B %e";
          timestr = "%I:%M %p";
          fade-in = 0.2;
          ignore-empty-password = true;
        };
      };
    };
  };
}
