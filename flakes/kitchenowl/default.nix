{pkgs, ...}:{
  nixpkgs.overlays = [
    (self: super: {
      kitchenowl = pkgs.callPackage ./kitchenowl.nix {};
    })
  ];
}