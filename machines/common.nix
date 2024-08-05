{ pkgs, lib, ... }: {
  networking.networkmanager.enable = lib.mkDefault true;
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
