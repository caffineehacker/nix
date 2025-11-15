{ pkgs, ... }: {
  boot = {
    plymouth = {
      enable = true;
      theme = "hexagon_hud";
      themePackages = with pkgs; [
        adi1090x-plymouth-themes
      ];
    };

    kernelParams = [
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };
}
