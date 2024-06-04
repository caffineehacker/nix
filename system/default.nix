{ ...
}: {
  imports = [
    ./ascii-workaround.nix
    ./secureboot.nix
    ./tpm.nix
  ];
}
