{
  description = "Framework Laptop EC Tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
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
          pkgs.stdenv.mkDerivation {
            pname = "fw-ectool";
            inherit version;
            src = pkgs.fetchFromGitLab {
              domain = "gitlab.howett.net";
              owner = "DHowett";
              repo = "ectool";
              rev = "0ac6155abbb7d4622d3bcf2cdf026dde2f80dad7";
              hash = "sha256-EMOliuyWB0xyrYB+E9axZtJawnIVIAM5nx026tESi38=";
            };
            buildInputs = with pkgs; [
              libftdi1
              libusb
            ];
            nativeBuildInputs = with pkgs; [
              pkg-config
              hostname
              cmake
            ];
            installPhase = ''
              install -D src/ectool $out/bin/ectool
            '';

            meta = with pkgs.lib; {
              description = "EC-Tool adjusted for usage with framework embedded controller";
              homepage = "https://github.com/DHowett/framework-ec";
              license = licenses.bsd3;
              platforms = platforms.linux;
              mainProgram = "ectool";
            };
          };
      });
    };
}
