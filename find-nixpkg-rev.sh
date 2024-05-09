#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq

# We use electron since it takes forever to build
JOBSETEVAL=$(curl -L -H 'Accept: application/json' https://hydra.nixos.org/job/nixos/trunk-combined/nixpkgs.electron.x86_64-linux/latest-finished | jq .jobsetevals[0])
REVISION=$(curl -L -H 'Accept: application/json' https://hydra.nixos.org/eval/$JOBSETEVAL | jq .jobsetevalinputs.nixpkgs.revision)
echo $REVISION