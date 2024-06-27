#!/usr/bin/env bash
set -e

HOSTNAME=homelab
if [[ "$1" -eq "mobile" ]]; then
    HOSTNAME=homelab.timwaterhouse.com
fi
nixos-rebuild switch --flake .#homelab --use-remote-sudo --target-host $HOSTNAME --build-host $HOSTNAME --keep-failed