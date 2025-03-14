{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.tw.services.ssh;
in
{
  options = {
    tw.services.ssh.enable = lib.mkOption {
      default = true;
      example = true;
      description = ''
        Enable the ssh shell
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      # require public key authentication for better security
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };

    # Don't enable SSH without fail2ban
    services.fail2ban.enable = true;

    programs.mosh.enable = true;

    environment.systemPackages = [
      pkgs.zellij
    ];
  };
}
