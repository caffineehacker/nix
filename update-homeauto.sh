#!/usr/bin/env bash
set -e

nixos-rebuild switch --flake .#homeauto --sudo --ask-sudo-password --target-host homeauto --keep-failed