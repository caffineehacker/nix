{ config, ... }:
{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "root" "tim" ];
    settings.show-trace = true;

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  networking = {
    hostName = "homeauto";
    wireless.enable = true;
  };

  time.timeZone = "America/Los_Angeles";

  tw.services.ssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = config.users.users.tim.openssh.authorizedKeys.keys;
  systemd.network.enable = true;

  tw.users.tim.enable = true;

  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;

  # Trim ssd for longer life and better storage
  services.fstrim.enable = true;

  system.stateVersion = "26.05";
}
