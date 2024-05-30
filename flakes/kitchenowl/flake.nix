{
  description = "Kitchen Owl";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    overlays = {
      default = (final: prev: {
        
      });
    };
    packages = {
        default = import 
      });

    legacyPackages.x86_64-linux.fw-inputmodule = self.packages.x86_64-linux.default;
  };
}