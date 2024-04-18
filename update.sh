#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nh

nh os switch --ask --update $(dirname "$0")
nh clean all --ask --keep 5 --keep-since 30d