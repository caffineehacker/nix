#!/usr/bin/env bash
set -e

nixos-rebuild switch --flake .#homelab --use-remote-sudo --target-host homelab --build-host homelab