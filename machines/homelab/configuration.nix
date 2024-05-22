{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = ["root" "tim"];
    settings.show-trace = true;
  };
  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.memtest86.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.grub.device = "nodev";
  boot.kernelPackages = pkgs.linuxPackages_zen;

  tw.services.ssh.enable = true;

  networking.hostName = "homelab";
  systemd.network.enable = true;
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;

  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];

  tw.users.tim.enable = true;

  environment.systemPackages = with pkgs; [
  ];

  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;

  boot.kernel.sysctl = {
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  # Trim ssd for longer life and better storage
  services.fstrim.enable = true;

  services.logind.extraConfig = ''
    # don't shutdown when power button is short-pressed
    HandlePowerKey=suspend
  '';

  system.stateVersion = "23.11";
}

