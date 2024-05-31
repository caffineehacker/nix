#!/usr/bin/env bash
set -e

nixos-rebuild switch --flake .#cloud --target-host root@129.153.214.198 --keep-failed