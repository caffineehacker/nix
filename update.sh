#!/bin/sh
set -e
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

nix flake update
nixos-rebuild build --flake .
nvd diff /var/run/current-system ./result
echo "Press enter to continue..."
read
nixos-rebuild switch --flake .