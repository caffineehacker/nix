#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash sops

sops updatekeys secrets/*.yaml