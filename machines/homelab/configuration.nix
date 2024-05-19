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

  imports = [
    ../common.nix
  ];

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

  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "enp30s0";
  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];

  tw.users.tim.enable = true;

  environment.systemPackages = with pkgs; [
  ];

  services.fwupd.enable = true;

  # Trim ssd for longer life and better storage
  services.fstrim.enable = true;

  services.logind.extraConfig = ''
    # don't shutdown when power button is short-pressed
    HandlePowerKey=suspend
  '';

  system.stateVersion = "23.11";
}

