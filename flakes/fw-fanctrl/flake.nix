{
  description = "Framework Laptop EC Tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fw-ectool.url = "./../fw-ectool";
  };

  outputs = { self, nixpkgs, fw-ectool }:
    let
      version = "unstable-2024-04-23";
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      packages = forAllSystems ({ pkgs }: {
        default =
          pkgs.python3Packages.buildPythonPackage {
            pname = "fw-fanctrl";
            inherit version;
            src = pkgs.fetchFromGitHub {
              owner = "TamtamHero";
              repo = "fw-fanctrl";
              rev = "c9397abf2fe8fcec67db1479e431eb142c9d1b18";
              sha256 = "sha256-EucUv8X1vGJGIo2wrs8MyK/nyEPvvsHEs4Cpgo8BQdo=";
            };
            propagatedBuildInputs = [ pkgs.python3Packages.watchdog ];

            makeWrapperArgs = [
              "--prefix PATH : ${pkgs.lib.makeBinPath [ 
              pkgs.bash
              pkgs.lm_sensors
              pkgs.fw-ectool
            ]}"
            ];

            patches = [ ./add-setup-py.patch ./bash-fix.patch ./ignore-zero.patch ./leave-speed-init.patch ];

            setuptoolsBuildPhase = "true";

            meta = with pkgs.lib; {
              description = "Framework Fan Control Service";
              homepage = "https://github.com/TamtamHero/fw-fanctrl";
              license = licenses.bsd3;
              platforms = platforms.linux;
              mainProgram = "fanctrl.py";
            };
          };
      });
      nixosModules.default = inputs: { config
                                     , lib
                                     , pkgs
                                     , ...
                                     }:
        let
          cfg = config.services.fw-fanctrl;
        in
        {
          services.fw-fanctrl.enable = lib.mkEnableOption "fw-fanctrl";

          config = lib.mkIf cfg.enable {
            systemd.services.fw-fanctrl = {
              description = "Framework fan controller.";
              environment = {
                PYTHONUNBUFFERED = "1";
              };

              after = [ "multi-user.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                ExecStart = "${pkgs.fw-fanctrl}/bin/fanctrl.py --config ${cfg.configJsonPath}";
                Type = "simple";
              };
            };
          };
        };
    };
}
