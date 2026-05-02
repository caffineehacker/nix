{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.tw.services.waydroid;
in
{
  options = {
    tw.services.waydroid.enable = lib.mkOption {
      default = true;
      example = true;
      description = ''
        Enable waydroid services
      '';
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
    virtualisation.waydroid.package = pkgs.waydroid-nftables;
    networking.firewall.trustedInterfaces = [ "waydroid0" ];

    environment.systemPackages = [
      pkgs.waydroid-helper
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
