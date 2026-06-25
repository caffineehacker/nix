{ config, lib, pkgs, ... }:
let
  cfg = config.tw.containers.airplane;
  helpers = import ./helpers.nix { inherit lib; };
in
{
  imports = [ (helpers.module cfg) ];

  config = lib.mkIf cfg.enable {
    # Disable module so dump1090 can read from the SDR stick
    boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];
    services.udev.extraRules = ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", ENV{ID_SOFTWARE_RADIO}="1", MODE="0660", GROUP="plugdev", SYMLINK+="rtl_sdr"
    '';

    users.groups.plugdev = { };

    containers."${cfg.name}" = {
      allowedDevices = [
        {
          node = "char-usb_device";
          modifier = "rwm";
        }
      ];
      bindMounts."/dev/bus/usb" = { hostPath = "/dev/bus/usb"; isReadOnly = false; };
      bindMounts."/dev/rtl_sdr" = { hostPath = "/dev/rtl_sdr"; isReadOnly = false; };

      config = { ... }: {
        imports = [ (helpers.containerConfigModule cfg) ];

        systemd.services.chownRtlDev = {
          serviceConfig = {
            Type = "oneshot";
          };
          wantedBy = [ "dump1090-fa.service" ];
          script = ''
            chown root:plugdev $(readlink -f /dev/rtl_sdr) 
          '';
        };

        environment.systemPackages = [
          pkgs.dump1090-fa
        ];

        services.dump1090-fa.enable = true;
        services.dump1090-fa.extraArgs = [
          "--quiet"
          "--enable-agc"
          "--lat"
          "47.659"
          "--lon"
          "-122.36"
        ];

        services.nginx = {
          enable = true;
          virtualHosts."default" = {
            listen = [
              {
                addr = "0.0.0.0";
                port = cfg.cloudflare.port;
              }
            ];
            locations."/data/" = {
              alias = "/run/dump1090-fa/";
              extraConfig = "expires off;";
            };
            locations."/" = {
              alias = "${pkgs.dump1090-fa}/share/dump1090/";
              index = "index.html";
            };
          };
        };
      };
    };
  };
}
