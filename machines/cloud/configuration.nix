{ config, pkgs, ... }: {
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "root" "tim" ];
    settings.show-trace = true;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cloud"; # Define your hostname.
  systemd.network.enable = true;
  networking.networkmanager.enable = false;
  networking.useNetworkd = true;
  services.fail2ban = {
    enable = true;
    # Ban IP after 5 failures
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      # Enable increment of bantime after each violation
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      # Do not ban for more than 1 week
      maxtime = "168h";
      # Calculate the bantime based on all the violations
      overalljails = true;
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "tim@timwaterhouse.com";
  };

  services.openssh.enable = true;

  tw.users.tim.enable = true;
  users.users.root.openssh.authorizedKeys.keys = config.users.users.tim.openssh.authorizedKeys.keys;

  nix.gc.automatic = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
