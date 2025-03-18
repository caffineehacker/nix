#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nh
set -e

nh os switch --ask --update $(dirname "$0") -- --keep-failed --keep-going
echo "Press enter to continue..."
read
nh clean all --ask --keep 5 --keep-since 30d