#!/usr/bin/env bash
set -e
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

nix flake update
nixos-rebuild boot --flake . --upgrade-all
nvd diff /var/run/current-system /nix/var/nix/profiles/system-$(nix-env --list-generations -p /nix/var/nix/profiles/system | tail -n1 | grep -Po "\d+" | head -n1)-link
echo "Press enter to continue..."
read
/nix/var/nix/profiles/system-$(nix-env --list-generations -p /nix/var/nix/profiles/system | tail -n1 | grep -Po "\d+" | head -n1)-link/bin/switch-to-configuration switch