{ ...
}: {
  imports = [
    ./secureboot.nix
    ./tpm.nix
    ./ui.nix
  ];
}
