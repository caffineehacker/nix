{ pkgs, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      logiops = prev.logiops.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch {
            url = "https://github.com/PixlOne/logiops/commit/91aa0c12175f33a4184ccaf41181b0a799f7cc55.patch";
            hash = "sha256-A+StDD+Dp7lPWVpuYR9JR5RuvwPU/5h50B0lY8Qu7nY=";
          })
        ];
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    logiops
  ];

  # Create systemd service
  # https://github.com/PixlOne/logiops/blob/5547f52cadd2322261b9fbdf445e954b49dfbe21/src/logid/logid.service.in
  systemd.services.logiops = {
    description = "Logitech Configuration Daemon";
    startLimitIntervalSec = 0;
    after = [ "multi-user.target" ];
    wantedBy = [ "graphical.target" ];
    wants = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.logiops}/bin/logid -v -c /etc/logid.cfg";
      User = "root";
    };
  };

  # Add a `udev` rule to restart `logiops` when the mouse is connected
  # https://github.com/PixlOne/logiops/issues/239#issuecomment-1044122412
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{id/vendor}=="046d", RUN{program}="${pkgs.systemd}/bin/systemctl --no-block try-restart logiops.service"
  '';

  # Configuration for logiops
  environment.etc."logid.cfg".text = ''
    devices: ({
        name: "MX Master 4";
        dpi: 1000;
        smartshift:
        {
            on: true;
            threshold: 30;
            torque: 50;
        };
        hiresscroll:
        {
            hires: false;
            invert: false;
            target: false;
        };
        thumbwheel:
        {
            divert: true;
            left: {
                mode: "OnInterval";
                interval: 3;
                direction: "Left";
                action =
                {
                    type: "Keypress";
                    keys: ["KEY_LEFT"];
                };
            },
            right: {
                mode: "OnInterval";
                interval: 3;
                direction: "Right";
                action =
                {
                    type: "Keypress";
                    keys: ["KEY_RIGHT"];
                };
            }
        }
        buttons: (
        {
            cid: 0xc3;
            action =
            {
                type: "Gestures";
                gestures: (
                {
                    direction: "Up";
                    mode: "OnRelease";
                    action =
                    {
                        type: "None";
                   };
                },
                {
                    direction: "Down";
                    mode: "OnRelease";
                    action =
                    {
                        type: "None";
                    };
                    },
                {
                    direction: "Left";
                    mode: "OnRelease";
                    action =
                    {
                        type: "Keypress";
                        keys: ["KEY_LEFTCTRL", "KEY_C"];
                    }
                    },
                {
                    direction: "Right";
                    mode: "OnRelease";
                    action =
                    {
                        type: "Keypress";
                        keys: ["KEY_LEFTCTRL", "KEY_V"];
                    }
                    },
                {
                    direction: "None"
                    mode: "OnRelease";
                    action =
                    {
                        type: "Keypress";
                        keys: ["KEY_ENTER"];
                    }
                });
            };
        },
        {
            cid: 0xc4;
            action =
            {
                type: "ToggleSmartshift";
            };
        },
        {
            cid: 0x56;
            action =
            {
                type: "Keypress";
                keys: ["KEY_FORWARD"]
            }
        },
        {
            cid: 0x53;
            action =
            {
                type: "Keypress";
                keys: ["KEY_BACK"]
            }
        });
    });
  '';
}
