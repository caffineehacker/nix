#!/usr/bin/env bash
set -e

HOSTNAME=homelab
if [[ "$1" == "mobile" ]]; then
    HOSTNAME=homelab.timwaterhouse.com
fi
echo Using $HOSTNAME
nixos-rebuild switch --flake .#homelab --use-remote-sudo --target-host $HOSTNAME --build-host $HOSTNAME --keep-failed