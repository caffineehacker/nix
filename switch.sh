#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nh
set -e

nh os switch --ask $(dirname "$0") -- -j 2