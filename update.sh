#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nh
set -e

./find-hyprland-updates.sh
# This will get the latest passing hydra build
sed -i "s/^\(\s*\).*\( ### REPLACE_NIXPKGS_REV$\)/\1rev = $(./find-nixpkg-rev.sh);\2/g" flake.nix
nh os switch --ask --update $(dirname "$0") -- -j 2 --keep-failed --keep-going
echo "Press enter to continue..."
read
nh clean all --ask --keep 5 --keep-since 30d