{
  description = "Framework Laptop Input Module Control Program";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      version = "0.2.0";
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
      ];

      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; overlays = [ rust-overlay.overlays.default ]; };
      });
    in
    {
      overlays = {
        default = (final: prev: {
          fw-inputmodule = self.packages.x86_64-linux.default;
        });
      };
      packages = forAllSystems ({ pkgs }:
        let
          rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        in
        {
          default =
            pkgs.rustPlatform.buildRustPackage {
              pname = "fw-inputmodule";
              inherit version;
              src = pkgs.fetchFromGitHub {
                owner = "FrameworkComputer";
                repo = "inputmodule-rs";
                rev = "v0.2.0";
                hash = "sha256-5sqTkaGqmKDDH7byDZ84rzB3FTu9AKsWxA6EIvUrLCU=";
              };

              cargoLock = {
                lockFile = ./Cargo.lock;
                outputHashes = {
                  "st7306-0.8.2" = "sha256-YTFVedMnt+fMZ9zs/LaEpJ+w6qOWyLNg+6Afo2+Uzls=";
                  "vis-core-0.1.0" = "sha256-Jw0UMBT/ddNzILAIEHwgcvqvuPDaJmjzoLUcTQMpWe8=";
                };
              };

              nativeBuildInputs = with pkgs; [
                rust
                pkg-config
                cargo-make
              ];

              buildInputs = with pkgs; [
                systemd
              ];

              buildPhase = ''
                cargo make --cwd inputmodule-control build-release
              '';

              installPhase = ''
                mkdir -p $out/bin
                cp target/x86_64-unknown-linux-gnu/release/inputmodule-control $out/bin/
              '';

              meta = with pkgs.lib; {
                description = "Framework laptops tool for interacting with input modules";
                homepage = "https://github.com/FrameworkComputer/inputmodule-rs";
                license = licenses.mit;
                platforms = platforms.linux;
                mainProgram = "inputmodule-control";
              };
            };
        });

      legacyPackages.x86_64-linux.fw-inputmodule = self.packages.x86_64-linux.default;
    };
}
