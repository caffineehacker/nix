{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "root" "tim" ];
    settings.show-trace = true;
  };
  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  boot = {
    loader = {
      systemd-boot = {
        configurationLimit = 5;
        memtest86.enable = true;
        enable = true;
      };
      efi.canTouchEfiVariables = true;
      grub.device = "nodev";
    };
    initrd = {
      systemd = {
        enable = true;
        tpm2.enable = false;
      };
    };
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      # I get random hangs / crashes, trying lots of things
      "acpi=off"
      "noapic"
      "processor.max_cstate=2"
    ];
    kernel.sysctl = {
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
    };
  };

  tw.services.ssh.enable = true;

  networking.hostName = "homelab";
  systemd.network.enable = true;
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;
  services.fail2ban.enable = true;

  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];

  tw.users.tim.enable = true;

  services.fwupd = {
    enable = true;
    daemonSettings.DisabledPlugins = [ "test" "test_ble" "invalid" "bios" ];
  };
  services.power-profiles-daemon.enable = true;

  # Trim ssd for longer life and better storage
  services.fstrim.enable = true;

  system.stateVersion = "23.11";
}

