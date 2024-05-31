#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash sops

# Update .sops.yaml to add keys
# To produce keys run `nix-shell -p ssh-to-age --run 'ssh-keyscan <server> | ssh-to-age'`

sops updatekeys secrets/*.yaml