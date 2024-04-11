#!/bin/sh
set -e
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

nix flake update
nixos-rebuild switch --flake .