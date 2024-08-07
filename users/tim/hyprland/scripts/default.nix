{ ... }: {
  nixpkgs.overlays = [
    (self: super: {
      tw.hypr.brightness = super.writeShellApplication {
        name = "brightness";
        runtimeInputs = with super; [ libnotify brightnessctl ];
        text = builtins.readFile ./brightness;
      };

      tw.hypr.kb-brightness = super.writeShellApplication {
        name = "kb-brightness";
        runtimeInputs = with super; [ libnotify brightnessctl ];
        text = builtins.readFile ./kb-brightness;
      };

      tw.hypr.volume = super.writeShellApplication {
        name = "volume";
        runtimeInputs = with super; [ libnotify pamixer ];
        text = builtins.readFile ./volume;
      };

      tw.hypr.waybar-weather = super.stdenv.mkDerivation {
        name = "waybar-weather";
        buildInputs = [ super.makeWrapper super.python3Packages.wrapPython ];
        src = ./.;
        pythonPath = [
          super.python3Packages.requests
        ];
        installPhase = ''
          mkdir -p $out/bin

          cp waybar-wttr.py $out/bin
        '';
        fixupPhase = "wrapPythonPrograms";
      };
    })
  ];
}
