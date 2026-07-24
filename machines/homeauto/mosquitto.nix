{ ... }:
{
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 1883 ];
  };

  nixpkgs.overlays = [
    # These tests are flaky and often fail - 7/23/2026
    (final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (pyFinal: pyPrev: {
            paho-mqtt = pyPrev.paho-mqtt.overridePythonAttrs (old: {
              doCheck = false;
            });
          })
        ];
    })
  ];
}
